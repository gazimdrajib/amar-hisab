import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../modules/sync/application/services/sync_engine.dart'
    show ChangeLogSource;

/// Allowed `change_log.operation` values (Database Book §3.9).
class ChangeOperation {
  ChangeOperation._();
  static const insert = 'INSERT';
  static const update = 'UPDATE';
  static const delete = 'DELETE';
}

/// One row of the transactional outbox (`change_log` table).
class ChangeEntry {
  const ChangeEntry({
    required this.id,
    required this.changeId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.payload,
    this.oldValues,
    required this.timestampMs,
    required this.sequence,
    required this.syncStatus,
    required this.deviceId,
    required this.businessId,
  });

  factory ChangeEntry.fromRow(Map<String, Object?> row) => ChangeEntry(
        id: row['id'] as int,
        changeId: row['change_id'] as String,
        entityType: row['entity_type'] as String,
        entityId: row['entity_id'] as int,
        operation: row['operation'] as String,
        payload: row['payload'] as String?,
        oldValues: row['old_values'] as String?,
        timestampMs: row['timestamp_ms'] as int,
        sequence: row['sequence'] as int,
        syncStatus: row['sync_status'] as String,
        deviceId: row['device_id'] as String,
        businessId: row['business_id'] as int,
      );

  final int id;
  final String changeId;
  final String entityType;
  final int entityId;
  final String operation;
  final String? payload;
  final String? oldValues;
  final int timestampMs;
  final int sequence;
  final String syncStatus;
  final String deviceId;
  final int businessId;
}

/// Transactional outbox writer (Architecture Book §16.4, Event Catalog §4).
///
/// [recordChange] MUST be called **inside the same transaction** as the
/// business data mutation it describes; it never opens a transaction itself.
/// The sync engine later reads rows with `sync_status = 'pending'` and pushes
/// them to the Cloud Sync Service.
///
/// All SQL is parameterised.
class ChangeLogService implements ChangeLogSource {
  ChangeLogService(this._db);

  final Database _db;

  String? _deviceId;

  /// A change that originated on this device.
  static const originLocal = 'local';

  /// A change applied from a remote device through sync (`applyChange`). Such
  /// rows are inserted with `sync_status = 'synced'` so the sync engine never
  /// pushes them back to the cloud (loop prevention, Event Catalog §5.2).
  static const originRemote = 'remote';

  /// Stable identifier of this device, used both for `change_log.device_id`
  /// and for gRPC authentication metadata. Loaded from (in order):
  ///  1. `DEVICE_ID` environment variable, or
  ///  2. the single row of `device_registry`, or
  ///  3. a freshly generated UUID persisted to `device_registry`.
  @override
  String get deviceId => _deviceId ??= _resolveDeviceId();

  String _resolveDeviceId() {
    final fromEnv = Platform.environment['DEVICE_ID'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    final rows = _db.select(
      'SELECT device_id FROM device_registry ORDER BY id LIMIT 1;',
    );
    if (rows.isNotEmpty) return rows.first['device_id'] as String;

    final generated = _uuid();
    final businessId = _defaultBusinessId();
    _db.execute(
      'INSERT OR IGNORE INTO device_registry '
      '(device_id, business_id, device_name, is_authorized) '
      'VALUES (?, ?, ?, 1);',
      [generated, businessId, Platform.localHostname],
    );
    return generated;
  }

  int _defaultBusinessId() {
    final rows = _db.select('SELECT id FROM businesses ORDER BY id LIMIT 1;');
    if (rows.isNotEmpty) return rows.first['id'] as int;
    // On very first boot the seeding order may leave businesses empty; upsert
    // the default tenant so the FK on device_registry is always satisfied.
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT OR IGNORE INTO businesses (id, name, type, currency, is_active, created_at, updated_at) '
      "VALUES (1, ?, 'retail', 'BDT', 1, ?, ?);",
      ['Default Business', now, now],
    );
    final again = _db.select('SELECT id FROM businesses ORDER BY id LIMIT 1;');
    if (again.isEmpty) {
      throw StateError(
          'businesses table is empty and could not be seeded with a default row');
    }
    return again.first['id'] as int;
  }

  /// Next per-device monotonic sequence number.
  int nextSequence() {
    final rows = _db.select(
      'SELECT COALESCE(MAX(sequence), 0) + 1 AS next_seq '
      'FROM change_log WHERE device_id = ?;',
      [deviceId],
    );
    return rows.first['next_seq'] as int;
  }

  /// Append one outbox row. Pass [payload] as the full snapshot for
  /// INSERT/UPDATE ([ChangeOperation.insert]/[ChangeOperation.update]) and
  /// [oldValues] for UPDATE/[ChangeOperation.delete] (Event Catalog §4.1).
  ///
  /// Returns the assigned [ChangeEntry.changeId] (UUID).
  String recordChange({
    required String entityType,
    required int entityId,
    required String operation,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? oldValues,
    required int businessId,
    String origin = originLocal,
  }) {
    final changeId = _uuid();
    _db.execute(
      'INSERT INTO change_log '
      '(change_id, entity_type, entity_id, operation, payload, old_values, '
      ' timestamp_ms, sequence, sync_status, device_id, business_id) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        changeId,
        entityType,
        entityId,
        operation,
        payload == null ? null : jsonEncode(payload),
        oldValues == null ? null : jsonEncode(oldValues),
        DateTime.now().toUtc().millisecondsSinceEpoch,
        nextSequence(),
        origin == originRemote ? 'synced' : 'pending',
        deviceId,
        businessId,
      ],
    );
    return changeId;
  }

  /// Apply a change received from the cloud: writes it into the outbox marked
  /// `synced` (never re-pushed) so a full local history is preserved.
  ///
  /// Idempotent on [changeId] (`INSERT OR IGNORE` against the UNIQUE index);
  /// duplicate deliveries are silently acknowledged (Proto Book §4.1).
  bool recordRemoteChange({
    required String changeId,
    required String entityType,
    required int entityId,
    required String operation,
    String? payload,
    String? oldValues,
    required int timestampMs,
    required int sequence,
    required String sourceDeviceId,
    required int businessId,
  }) {
    _db.execute(
      'INSERT OR IGNORE INTO change_log '
      '(change_id, entity_type, entity_id, operation, payload, old_values, '
      ' timestamp_ms, sequence, sync_status, device_id, business_id) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        changeId,
        entityType,
        entityId,
        operation,
        payload,
        oldValues,
        timestampMs,
        sequence,
        'synced',
        sourceDeviceId,
        businessId,
      ],
    );
    return _db.updatedRows > 0;
  }

  /// True when [changeId] is already present (any status) – deduplication for
  /// at-least-once delivery (Event Catalog §4).
  bool isKnown(String changeId) {
    final rows = _db.select(
      'SELECT 1 FROM change_log WHERE change_id = ? LIMIT 1;',
      [changeId],
    );
    return rows.isNotEmpty;
  }

  /// Up to [limit] pending changes for this device, oldest first.
  List<ChangeEntry> pending({int limit = 500}) {
    final rows = _db.select(
      'SELECT * FROM change_log '
      "WHERE sync_status = 'pending' AND device_id = ? "
      'ORDER BY sequence ASC LIMIT ?;',
      [deviceId, limit],
    );
    return rows.map(ChangeEntry.fromRow).toList();
  }

  /// Mark a batch as successfully synced.
  void markSynced(Iterable<String> changeIds) {
    for (final id in changeIds) {
      _db.execute(
        "UPDATE change_log SET sync_status = 'synced' WHERE change_id = ?;",
        [id],
      );
    }
  }

  /// Mark a batch as conflicted (kept for operator inspection / resolution).
  void markConflict(Iterable<String> changeIds) {
    for (final id in changeIds) {
      _db.execute(
        "UPDATE change_log SET sync_status = 'conflict' WHERE change_id = ?;",
        [id],
      );
    }
  }

  /// Count of rows still awaiting push.
  int pendingCount() {
    final rows = _db.select(
      'SELECT COUNT(*) AS c FROM change_log '
      "WHERE sync_status = 'pending' AND device_id = ?;",
      [deviceId],
    );
    return rows.first['c'] as int;
  }

  /// RFC-4122 v4 UUID (no external dependency).
  static String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant 10xx
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  /// HMAC secret derived for the device JWT fallback authentication
  /// (cloud exchanges it for a session token). Never hard-coded – requires
  /// `DEVICE_SECRET` env; absent in pure offline mode.
  static String? deviceProof(String deviceId) {
    final secret = Platform.environment['DEVICE_SECRET'];
    if (secret == null || secret.isEmpty) return null;
    return Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode(deviceId))
        .toString();
  }
}
