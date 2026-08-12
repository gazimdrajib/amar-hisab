import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../infrastructure/repositories/sync_repository.dart';

/// Conflict-resolution rules (Architecture Book §17 / Phase 9 Part E).
///
/// The resolver decides, for a remote change, which version of a row wins.
/// Outcomes are expressed as the set of SQL writes the applier must run; the
/// resolver itself only READS the local row for comparison.
///
/// Strategies:
///  * LWW (default)    – newest `timestamp_ms` wins.
///  * fieldMerge       – per-field merge for contact-ish master data
///                       (`customers`, `suppliers`): for each field, the side
///                       with the newer non-null value wins; nulls never
///                       overwrite non-nulls.
///  * appendOnly       – `journal_entries`, `journal_lines`,
///                       `stock_movements`: immutable; INSERT always wins,
///                       UPDATE/DELETE from a peer are treated as conflicts.
///  * eventSourced     – `stock`, `batches.quantity`: never merged; replayed
///                       from `stock_movements` (see [ChangeApplier]).
enum ConflictStrategy { lww, fieldMerge, appendOnly, eventSourced }

/// Decision returned by [ConflictResolver.resolve].
class Resolution {
  const Resolution.applyRemote()
      : apply = true,
        isConflict = false,
        mergedPayload = null,
        reason = null;

  const Resolution.keepLocal()
      : apply = false,
        isConflict = false,
        mergedPayload = null,
        reason = null;

  const Resolution.applyMerged(this.mergedPayload)
      : apply = true,
        isConflict = false,
        reason = null;

  const Resolution.conflict(this.reason)
      : apply = false,
        isConflict = true,
        mergedPayload = null;

  /// Whether the remote change should be written to the local DB.
  final bool apply;

  /// Whether a real conflict was detected (both sides diverged and the
  /// strategy could not decide cleanly). Conflicted changes keep the local
  /// version and mark the outbox row `conflict`.
  final bool isConflict;

  /// For fieldMerge: the merged JSON payload to write.
  final Map<String, dynamic>? mergedPayload;

  /// Human-readable reason stored beside conflicted rows.
  final String? reason;
}

/// Decides how a remote [RemoteChange] interacts with local state.
class ConflictResolver {
  ConflictResolver(this._db);

  final Database _db;

  /// Columns we never copy from a peer into local master data.
  static const _protectedKeys = {'id', 'business_id', 'created_at'};

  /// Strategies keyed by `entity_type` (Event Catalog §4 entity names).
  static const Map<String, ConflictStrategy> _strategies = {
    // Part E: field-level merge for customers & suppliers.
    'customers': ConflictStrategy.fieldMerge,
    'customer': ConflictStrategy.fieldMerge,
    'suppliers': ConflictStrategy.fieldMerge,
    'supplier': ConflictStrategy.fieldMerge,

    // Part E: journal entries are append-only.
    'journal_entries': ConflictStrategy.appendOnly,
    'journal_entry': ConflictStrategy.appendOnly,
    'journal_lines': ConflictStrategy.appendOnly,
    'journal_line': ConflictStrategy.appendOnly,

    // Part E: stock & batches are event-sourced (replayed, not merged).
    'stock': ConflictStrategy.eventSourced,
    'batches': ConflictStrategy.eventSourced,
    'batch': ConflictStrategy.eventSourced,

    // Stock movements themselves are immutable ledger rows.
    'stock_movements': ConflictStrategy.appendOnly,
    'stock_movement': ConflictStrategy.appendOnly,
  };

  ConflictStrategy strategyFor(String entityType) =>
      _strategies[entityType] ?? ConflictStrategy.lww;

  /// Resolve [remote] against the local row found via [currentRow].
  /// [currentRow] is null when the entity does not exist locally.
  Resolution resolve(
    RemoteChange remote,
    Map<String, Object?>? currentRow,
  ) {
    final strategy = strategyFor(remote.entityType);

    switch (strategy) {
      case ConflictStrategy.eventSourced:
        // Quantity columns must never be copied; stock is derived from the
        // stock_movements ledger. Only INSERT of non-existent rows applies.
        return remote.operation == 'INSERT' && currentRow == null
            ? const Resolution.applyRemote()
            : const Resolution.keepLocal();

      case ConflictStrategy.appendOnly:
        if (remote.operation == 'INSERT') {
          // Duplicate INSERT (same PK from another device) → conflict only if
          // the contents differ; identical contents are a no-op duplicate.
          if (currentRow == null) return const Resolution.applyRemote();
          final decoded = _decode(remote.payload);
          return _rowsEquivalent(currentRow, decoded)
              ? const Resolution.keepLocal()
              : const Resolution.conflict(
                  'append-only entity mutated on two devices');
        }
        // Remote UPDATE/DELETE on an append-only ledger row – reject.
        return const Resolution.conflict(
            'append-only entity does not accept UPDATE/DELETE');

      case ConflictStrategy.fieldMerge:
        if (remote.operation == 'INSERT') {
          return currentRow == null
              ? const Resolution.applyRemote()
              : Resolution.applyMerged(_merge(currentRow, remote));
        }
        if (remote.operation == 'DELETE') {
          // Never delete master data that's still referenced locally.
          return const Resolution.conflict(
              'remote delete of merged master data');
        }
        if (currentRow == null) return const Resolution.applyRemote();
        return Resolution.applyMerged(_merge(currentRow, remote));

      case ConflictStrategy.lww:
        if (currentRow == null) {
          return remote.operation == 'DELETE'
              ? const Resolution.keepLocal()
              : const Resolution.applyRemote();
        }
        // Last-Write-Wins on timestamp: peers carry the writer's local clock.
        final remoteTs = remote.timestampMs;
        final localTs = _localTimestampMs(currentRow);
        if (remote.operation == 'DELETE') {
          return remoteTs >= localTs
              ? const Resolution.applyRemote()
              : const Resolution.keepLocal();
        }
        if (remoteTs > localTs) return const Resolution.applyRemote();
        if (remoteTs == localTs) {
          // Deterministic tie-break: lexicographically larger change ID wins
          // so all devices converge regardless of delivery order.
          final localChange = _latestLocalChangeId(remote);
          if (localChange == null || remote.changeId.compareTo(localChange) > 0) {
            return const Resolution.applyRemote();
          }
        }
        return const Resolution.keepLocal();
    }
  }

  // -------------------------------------------------------------- internals

  Map<String, dynamic> _merge(
      Map<String, Object?> local, RemoteChange remote) {
    final merged = <String, dynamic>{...local};
    final incoming = _decode(remote.payload);
    incoming.forEach((key, value) {
      if (_protectedKeys.contains(key)) return;
      // Nulls never overwrite non-nulls; otherwise the peer's value wins for
      // fields it actually sent.
      if (value == null) return;
      merged[key] = value;
    });
    return merged;
  }

  bool _rowsEquivalent(Map<String, Object?> local, Map<String, dynamic> remote) {
    final keys = <String>{...local.keys, ...remote.keys}
        .where((k) => !_protectedKeys.contains(k) && k != 'updated_at');
    for (final key in keys) {
      final l = local[key];
      final r = remote[key];
      if (l is num && r is num) {
        if ((l.toDouble() - r.toDouble()).abs() > 0.0001) return false;
        continue;
      }
      if ('$l' != '$r') return false;
    }
    return true;
  }

  int _localTimestampMs(Map<String, Object?> row) {
    final v = row['updated_at'] ?? row['created_at'];
    if (v is String) {
      return DateTime.tryParse(v)?.toUtc().millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }

  String? _latestLocalChangeId(RemoteChange remote) {
    final rows = _db.select(
      'SELECT change_id FROM change_log '
      'WHERE entity_type = ? AND entity_id = ? AND business_id = ? '
      'ORDER BY id DESC LIMIT 1;',
      [remote.entityType, remote.entityId, remote.businessId],
    );
    if (rows.isEmpty) return null;
    return rows.first['change_id'] as String;
  }

  static Map<String, dynamic> _decode(String? payload) {
    if (payload == null || payload.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(payload);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
  }
}
