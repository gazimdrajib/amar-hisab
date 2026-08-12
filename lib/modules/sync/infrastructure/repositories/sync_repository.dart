import 'package:sqlite3/sqlite3.dart';

/// Whether a change originated locally (needs push) or remotely (pull).
enum ChangeOrigin { local, remote }

/// Applied remote change descriptor returned by [ChangeApplier.apply] and
/// persisted by the sync engine. Payloads are kept as raw JSON strings to
/// match the `change_log` column types exactly.
class RemoteChange {
  const RemoteChange({
    required this.changeId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.payload,
    this.oldValues,
    required this.timestampMs,
    required this.sequence,
    required this.deviceId,
    required this.businessId,
  });

  final String changeId;
  final String entityType;
  final int entityId;
  final String operation;
  final String? payload;
  final String? oldValues;
  final int timestampMs;
  final int sequence;
  final String deviceId;
  final int businessId;
}

/// Data-access facade over the sync tables (Database Book §3.9):
/// `change_log`, `sync_state`, `device_registry`.
///
/// All SQL is parameterised. Methods that mutate `change_log` never open a
/// transaction themselves – they are called inside the caller's transaction
/// (transactional outbox; Event Catalog §5.1).
class SyncRepository {
  SyncRepository(this._db);

  final Database _db;

  // ------------------------------------------------------------ change_log

  /// Append one outbox row. Returns the row's own change_id.
  String insertChange({
    required String changeId,
    required String entityType,
    required int entityId,
    required String operation,
    String? payload,
    String? oldValues,
    required int timestampMs,
    required int sequence,
    required String syncStatus,
    required String deviceId,
    required int businessId,
  }) {
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
        payload,
        oldValues,
        timestampMs,
        sequence,
        syncStatus,
        deviceId,
        businessId,
      ],
    );
    return changeId;
  }

  /// Idempotent insert – used when recording remote changes locally.
  bool insertChangeIfAbsent({
    required String changeId,
    required String entityType,
    required int entityId,
    required String operation,
    String? payload,
    String? oldValues,
    required int timestampMs,
    required int sequence,
    required String syncStatus,
    required String deviceId,
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
        syncStatus,
        deviceId,
        businessId,
      ],
    );
    return _db.updatedRows > 0;
  }

  bool changeExists(String changeId) {
    final rows = _db.select(
      'SELECT 1 FROM change_log WHERE change_id = ? LIMIT 1;',
      [changeId],
    );
    return rows.isNotEmpty;
  }

  /// Pending outbox rows for [deviceId], ordered for ordered push.
  List<Map<String, Object?>> pendingChanges(String deviceId,
      {int limit = 500}) {
    final rows = _db.select(
      "SELECT * FROM change_log WHERE sync_status = 'pending' "
      'AND device_id = ? ORDER BY sequence ASC LIMIT ?;',
      [deviceId, limit],
    );
    return rows.map((r) => Map<String, Object?>.from(r)).toList();
  }

  void markChangesSynced(Iterable<String> changeIds) {
    for (final id in changeIds) {
      _db.execute(
        "UPDATE change_log SET sync_status = 'synced' WHERE change_id = ?;",
        [id],
      );
    }
  }

  void markChangesConflict(Iterable<String> changeIds) {
    for (final id in changeIds) {
      _db.execute(
        "UPDATE change_log SET sync_status = 'conflict' WHERE change_id = ?;",
        [id],
      );
    }
  }

  int pendingCount(String deviceId) {
    final rows = _db.select(
      'SELECT COUNT(*) AS c FROM change_log '
      "WHERE sync_status = 'pending' AND device_id = ?;",
      [deviceId],
    );
    return rows.first['c'] as int;
  }

  int nextSequence(String deviceId) {
    final rows = _db.select(
      'SELECT COALESCE(MAX(sequence), 0) + 1 AS next_seq '
      'FROM change_log WHERE device_id = ?;',
      [deviceId],
    );
    return rows.first['next_seq'] as int;
  }

  // ------------------------------------------------------------ sync_state

  /// Highest local sequence already accepted by the cloud.
  int lastSyncedSequence(String deviceId) =>
      _readSyncStateInt(deviceId, 'last_synced_sequence');

  /// Highest global (cloud) sequence applied locally.
  int lastRemoteSequence(String deviceId) =>
      _readSyncStateInt(deviceId, 'last_remote_sequence');

  void savePushCursor(String deviceId, int lastSyncedSequence) {
    _upsertSyncState(deviceId, {
      'last_synced_sequence': lastSyncedSequence,
      'last_synced_timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
    });
  }

  void saveRemoteCursor(String deviceId, int lastRemoteSequence) {
    _upsertSyncState(deviceId, {'last_remote_sequence': lastRemoteSequence});
  }

  int _readSyncStateInt(String deviceId, String column) {
    final rows = _db.select(
      'SELECT $column AS v FROM sync_state WHERE device_id = ?;',
      [deviceId],
    );
    if (rows.isEmpty) return 0;
    return (rows.first['v'] as int?) ?? 0;
  }

  void _upsertSyncState(String deviceId, Map<String, Object?> values) {
    if (values.isEmpty) return;
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final existing = _db.select(
      'SELECT device_id FROM sync_state WHERE device_id = ?;',
      [deviceId],
    );
    if (existing.isEmpty) {
      _db.execute(
        'INSERT INTO sync_state '
        '(device_id, last_synced_sequence, last_synced_timestamp, '
        ' last_remote_sequence) VALUES (?, ?, ?, ?);',
        [
          deviceId,
          values['last_synced_sequence'] ?? 0,
          values['last_synced_timestamp'] ?? nowMs,
          values['last_remote_sequence'] ?? 0,
        ],
      );
      return;
    }
    final sets = <String>[];
    final args = <Object?>[];
    values.forEach((column, value) {
      sets.add('$column = ?');
      args.add(value);
    });
    args.add(deviceId);
    _db.execute(
      'UPDATE sync_state SET ${sets.join(', ')} WHERE device_id = ?;',
      args,
    );
  }

  // ------------------------------------------------------- device_registry

  /// Create the device row on first run (idempotent);
  /// returns false when the row already existed.
  bool registerDevice({
    required String deviceId,
    required int businessId,
    String? deviceName,
    String? publicKey,
  }) {
    _db.execute(
      'INSERT OR IGNORE INTO device_registry '
      '(device_id, business_id, device_name, public_key, is_authorized) '
      'VALUES (?, ?, ?, ?, 1);',
      [deviceId, businessId, deviceName, publicKey],
    );
    return _db.updatedRows > 0;
  }

  String? firstDeviceId() {
    final rows =
        _db.select('SELECT device_id FROM device_registry ORDER BY id LIMIT 1;');
    if (rows.isEmpty) return null;
    return rows.first['device_id'] as String;
  }

  /// Highest applied remote (global) sequence seen in the change log – used
  /// as a safety floor before pulling again.
  int maxRemoteSequence() {
    final rows = _db.select(
      'SELECT COALESCE(MAX(sequence), 0) AS m FROM change_log;',
    );
    return rows.first['m'] as int;
  }
}
