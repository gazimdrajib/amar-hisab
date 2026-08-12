import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../infrastructure/repositories/sync_repository.dart';
import 'conflict_resolver.dart';

/// Allowlist of `entity_type` → local table the applier is permitted to
/// write. Anything not listed is ignored (unknown entities from newer/older
/// versions are tolerated per Proto Book §6.2).
const Map<String, String> kSyncableTables = {
  'sale': 'sales',
  'sales': 'sales',
  'sale_item': 'sale_items',
  'sale_payment': 'sale_payments',
  'purchase': 'purchases',
  'purchases': 'purchases',
  'purchase_item': 'purchase_items',
  'supplier_payment': 'supplier_payments',
  'product': 'products',
  'products': 'products',
  'category': 'categories',
  'brand': 'brands',
  'unit': 'units',
  'warehouse': 'warehouses',
  'customer': 'customers',
  'customers': 'customers',
  'supplier': 'suppliers',
  'suppliers': 'suppliers',
  'batch': 'batches',
  'batches': 'batches',
  'stock': 'stock',
  'stock_movement': 'stock_movements',
  'journal_entry': 'journal_entries',
  'journal_line': 'journal_lines',
  'account': 'chart_of_accounts',
  'student': 'students',
  'students': 'students',
};

/// Tables whose quantity columns are replayed from stock_movements instead of
/// being copied during a pull (Part E – event-sourced inventory).
const Set<String> kEventSourcedQuantityTables = {'stock', 'batches'};

/// Applies remote [RemoteChange]s to the local SQLite database.
///
/// Guarantees (Event Catalog §5.2):
///  * Deduplication by `change_id` before touching business tables.
///  * All writes for one change run inside ONE transaction together with the
///    outbox bookkeeping row (which is marked `synced` so the change is never
///    pushed back).
///  * No domain events are fired for remotely applied changes (infinite-loop
///    prevention); local business rules re-evaluate afterwards.
class ChangeApplier {
  ChangeApplier(this._db, this._resolver, this._syncRepository);

  final Database _db;
  final ConflictResolver _resolver;
  final SyncRepository _syncRepository;

  /// Apply [remote] to the local database.
  ///
  /// Returns `true` when the change was (or had already been) applied and the
  /// pull cursor may advance past it; `false` when it was recorded as a
  /// conflict and requires operator attention.
  bool apply(RemoteChange remote) {
    // Idempotency: at-least-once delivery from the cloud means the same
    // change_id may arrive more than once (Proto Book §4.1).
    if (_syncRepository.changeExists(remote.changeId)) return true;

    final table = kSyncableTables[remote.entityType];
    if (table == null) {
      // Unknown entity type (newer schema). Record it so the cursor advances
      // but take no business action.
      _syncRepository.insertChangeIfAbsent(
        changeId: remote.changeId,
        entityType: remote.entityType,
        entityId: remote.entityId,
        operation: remote.operation,
        payload: remote.payload,
        oldValues: remote.oldValues,
        timestampMs: remote.timestampMs,
        sequence: remote.sequence,
        syncStatus: 'synced',
        deviceId: remote.deviceId,
        businessId: remote.businessId,
      );
      return true;
    }

    var ok = true;
    _db.execute('BEGIN IMMEDIATE;');
    try {
      final currentRow = _findRow(table, remote.entityId, remote.businessId);
      final resolution = _resolver.resolve(remote, currentRow);

      if (resolution.isConflict) {
        _syncRepository.insertChangeIfAbsent(
          changeId: remote.changeId,
          entityType: remote.entityType,
          entityId: remote.entityId,
          operation: remote.operation,
          payload: remote.payload,
          oldValues: remote.oldValues,
          timestampMs: remote.timestampMs,
          sequence: remote.sequence,
          syncStatus: 'conflict',
          deviceId: remote.deviceId,
          businessId: remote.businessId,
        );
        ok = false;
      } else if (resolution.apply) {
        _writeRow(
          table,
          remote,
          currentRow != null,
          mergedPayload: resolution.mergedPayload,
        );
        _syncRepository.insertChangeIfAbsent(
          changeId: remote.changeId,
          entityType: remote.entityType,
          entityId: remote.entityId,
          operation: remote.operation,
          payload: remote.payload,
          oldValues: remote.oldValues,
          timestampMs: remote.timestampMs,
          sequence: remote.sequence,
          syncStatus: 'synced',
          deviceId: remote.deviceId,
          businessId: remote.businessId,
        );
      } else {
        // Local version wins – still record the remote change so the cursor
        // advances and history is complete (marked synced, not pushed back).
        _syncRepository.insertChangeIfAbsent(
          changeId: remote.changeId,
          entityType: remote.entityType,
          entityId: remote.entityId,
          operation: remote.operation,
          payload: remote.payload,
          oldValues: remote.oldValues,
          timestampMs: remote.timestampMs,
          sequence: remote.sequence,
          syncStatus: 'synced',
          deviceId: remote.deviceId,
          businessId: remote.businessId,
        );
      }
      _db.execute('COMMIT;');
    } catch (_) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
    return ok;
  }

  // -------------------------------------------------------------- internals

  Map<String, Object?>? _findRow(String table, int id, int businessId) {
    final rows = _db.select(
      'SELECT * FROM "$table" WHERE id = ? AND business_id = ? LIMIT 1;',
      [id, businessId],
    );
    if (rows.isEmpty) return null;
    return Map<String, Object?>.from(rows.first);
  }

  void _writeRow(
    String table,
    RemoteChange remote,
    bool exists, {
    Map<String, dynamic>? mergedPayload,
  }) {
    switch (remote.operation) {
      case 'INSERT':
        final payload = _sanitise(table, mergedPayload ?? _decode(remote.payload));
        payload['id'] = remote.entityId;
        payload['business_id'] = remote.businessId;
        _insert(table, payload);
        break;
      case 'UPDATE':
        if (!exists) {
          // UPDATE for a row we never received: treat as upsert so replicas
          // converge even when the original INSERT was missed.
          final payload =
              _sanitise(table, mergedPayload ?? _decode(remote.payload));
          payload['id'] = remote.entityId;
          payload['business_id'] = remote.businessId;
          _insert(table, payload);
          return;
        }
        final payload = _sanitise(table, mergedPayload ?? _decode(remote.payload))
          ..remove('id')
          ..remove('business_id');
        if (payload.isEmpty) return;
        final sets = payload.keys.map((k) => '"$k" = ?').join(', ');
        _db.execute(
          'UPDATE "$table" SET $sets WHERE id = ? AND business_id = ?;',
          [...payload.values, remote.entityId, remote.businessId],
        );
        break;
      case 'DELETE':
        _db.execute(
          'DELETE FROM "$table" WHERE id = ? AND business_id = ?;',
          [remote.entityId, remote.businessId],
        );
        break;
    }
  }

  void _insert(String table, Map<String, dynamic> payload) {
    final columns = payload.keys.map((k) => '"$k"').join(', ');
    final marks = List.filled(payload.length, '?').join(', ');
    _db.execute(
      'INSERT OR REPLACE INTO "$table" ($columns) VALUES ($marks);',
      payload.values.toList(),
    );
  }

  /// Strip keys that must never come from a peer and, for event-sourced
  /// tables, strip quantity columns (Part E: replayed, not merged).
  Map<String, dynamic> _sanitise(String table, Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.from(raw);
    out.removeWhere((key, _) => key == 'created_at' || key.trim().isEmpty);
    if (kEventSourcedQuantityTables.contains(table)) {
      out.remove('quantity');
      out.remove('current_quantity');
    }
    return out;
  }

  static Map<String, dynamic> _decode(String? payload) {
    if (payload == null || payload.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(payload);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}
