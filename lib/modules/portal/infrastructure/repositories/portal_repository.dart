import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/student_token.dart';

/// CRUD over `portal_tokens` + read helpers over `students`.
/// All SQL is parameterised.
class PortalRepository {
  PortalRepository(this._db);

  final Database _db;

  // ------------------------------------------------------------ tokens ----

  StudentToken? findToken(String token) {
    final rows = _db.select(
      'SELECT * FROM portal_tokens WHERE token = ? LIMIT 1;',
      [token],
    );
    if (rows.isEmpty) return null;
    return _mapToken(rows.first);
  }

  StudentToken createToken(StudentToken token) {
    _db.execute(
      'INSERT INTO portal_tokens '
      '(business_id, student_id, batch_id, token, type, secret_hash, '
      ' expires_at, is_active, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        token.businessId,
        token.studentId,
        token.batchId,
        token.token,
        token.type,
        token.secretHash,
        token.expiresAt?.toUtc().toIso8601String(),
        token.isActive ? 1 : 0,
        (token.createdAt ?? DateTime.now()).toUtc().toIso8601String(),
      ],
    );
    return token.copyWith(id: _db.lastInsertRowId);
  }

  void deactivateToken(String token) {
    _db.execute(
      'UPDATE portal_tokens SET is_active = 0 WHERE token = ?;',
      [token],
    );
  }

  /// Student codes visible through a token:
  ///  * student token → just that student;
  ///  * batch token   → students of the batch;
  ///  * business token→ all active students of the business.
  List<String> studentIdsFor(StudentToken token) {
    ResultSet rows;
    switch (token.type) {
      case 'student':
        if (token.studentId == null) return const [];
        rows = _db.select(
          'SELECT student_code FROM students '
          'WHERE id = ? AND business_id = ? AND is_active = 1;',
          [token.studentId, token.businessId],
        );
        break;
      case 'batch':
        if (token.batchId == null) return const [];
        rows = _db.select(
          'SELECT student_code FROM students '
          'WHERE batch_id = ? AND business_id = ? AND is_active = 1;',
          [token.batchId, token.businessId],
        );
        break;
      default:
        rows = _db.select(
          'SELECT student_code FROM students '
          'WHERE business_id = ? AND is_active = 1;',
          [token.businessId],
        );
    }
    return [for (final r in rows) r['student_code'] as String];
  }

  // ---------------------------------------------------------- students ----

  Map<String, Object?>? findStudentByCode(int businessId, String code) {
    final rows = _db.select(
      'SELECT * FROM students WHERE business_id = ? AND student_code = ? '
      'LIMIT 1;',
      [businessId, code],
    );
    if (rows.isEmpty) return null;
    return Map<String, Object?>.from(rows.first);
  }

  void updateStudentSecret(int businessId, String studentCode, String digest) {
    _db.execute(
      'UPDATE students SET secret_hash = ?, updated_at = ? '
      'WHERE business_id = ? AND student_code = ?;',
      [
        digest,
        DateTime.now().toUtc().toIso8601String(),
        businessId,
        studentCode,
      ],
    );
  }

  bool studentVisibleThrough(StudentToken token, int studentId) {
    switch (token.type) {
      case 'student':
        return token.studentId == studentId;
      case 'batch':
        if (token.batchId == null) return false;
        final rows = _db.select(
          'SELECT 1 FROM students WHERE id = ? AND batch_id = ? LIMIT 1;',
          [studentId, token.batchId],
        );
        return rows.isNotEmpty;
      default:
        final rows = _db.select(
          'SELECT 1 FROM students WHERE id = ? AND business_id = ? LIMIT 1;',
          [studentId, token.businessId],
        );
        return rows.isNotEmpty;
    }
  }

  /// Fee summary for the portal: enrollments are not yet a first-class table,
  /// so the portal derives dues from sales whose note tag matches
  /// `student:<code>`. Returns (totalFee, paid, due).
  ({double totalFee, double paid, double due}) feeSummary(
      int businessId, String studentCode) {
    final tag = '%student:$studentCode%';
    final salesRows = _db.select(
      'SELECT COALESCE(SUM(grand_total),0) AS total, '
      'COALESCE(SUM(paid_amount),0) AS paid, '
      'COALESCE(SUM(due_amount),0) AS due '
      "FROM sales WHERE business_id = ? AND status != 'Cancelled' "
      'AND note LIKE ?;',
      [businessId, tag],
    );
    final row = salesRows.first;
    return (
      totalFee: (row['total'] as num).toDouble(),
      paid: (row['paid'] as num).toDouble(),
      due: (row['due'] as num).toDouble(),
    );
  }

  /// Attendance placeholder: 0 until the education module ships; the column
  /// shape is kept so portal clients can rely on the field being present.
  double attendancePercent(int businessId, int studentId) => 0;

  StudentToken _mapToken(Map<String, Object?> row) => StudentToken(
        id: row['id'] as int?,
        businessId: row['business_id'] as int,
        studentId: row['student_id'] as int?,
        batchId: row['batch_id'] as int?,
        token: row['token'] as String,
        type: row['type'] as String,
        secretHash: row['secret_hash'] as String?,
        expiresAt: row['expires_at'] == null
            ? null
            : DateTime.tryParse(row['expires_at'] as String),
        isActive: (row['is_active'] as int? ?? 1) == 1,
        createdAt: row['created_at'] == null
            ? null
            : DateTime.tryParse(row['created_at'] as String),
      );
}
