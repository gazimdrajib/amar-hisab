import 'package:sqlite3/sqlite3.dart';

/// Log of a single auditable change. Field-level changes produce one row per
/// field (with old/new values); entity-level events (create / delete /
/// transfer …) can pass a whole snapshot as `oldValue`/`newValue`.
class AuditEntry {
  const AuditEntry({
    this.userId,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.fieldName,
    this.oldValue,
    this.newValue,
    this.businessId,
  });

  final int? userId;
  final String entityType;
  final int entityId;
  final String action;
  final String? fieldName;
  final String? oldValue;
  final String? newValue;
  final int? businessId;
}

/// Thin service that appends rows to the `audit_log` table.
///
/// Every mutating service in a module receives an [AuditService] and calls
/// [log] after successful persistence. Uses parameterised SQL exclusively.
class AuditService {
  AuditService(this._db);

  final Database _db;

  /// Append one audit entry.
  void log(AuditEntry entry) {
    _db.execute(
      'INSERT INTO audit_log '
      '(timestamp, user_id, entity_type, entity_id, action, field_name, '
      ' old_value, new_value, business_id) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        DateTime.now().toUtc().toIso8601String(),
        entry.userId,
        entry.entityType,
        entry.entityId,
        entry.action,
        entry.fieldName,
        entry.oldValue,
        entry.newValue,
        entry.businessId,
      ],
    );
  }

  /// Convenience wrapper for common events.
  void logAction({
    int? userId,
    required String entityType,
    required int entityId,
    required String action,
    String? fieldName,
    String? oldValue,
    String? newValue,
    int? businessId,
  }) {
    log(AuditEntry(
      userId: userId,
      entityType: entityType,
      entityId: entityId,
      action: action,
      fieldName: fieldName,
      oldValue: oldValue,
      newValue: newValue,
      businessId: businessId,
    ));
  }

  /// Read recent audit entries for an entity (parametrised query).
  List<Map<String, Object?>> historyFor(String entityType, int entityId,
      {int limit = 100}) {
    final rows = _db.select(
      'SELECT * FROM audit_log WHERE entity_type = ? AND entity_id = ? '
      'ORDER BY id DESC LIMIT ?;',
      [entityType, entityId, limit],
    );
    return rows.map((r) => Map<String, Object?>.from(r)).toList();
  }
}
