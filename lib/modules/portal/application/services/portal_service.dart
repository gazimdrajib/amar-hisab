import 'dart:math';

import '../../../../core/services/audit_service.dart';
import '../../../../core/services/change_log_service.dart';
import '../../../../core/utils/hmac_helper.dart';
import '../../../../core/utils/jwt_helper.dart';
import '../../domain/entities/student_token.dart';
import '../../infrastructure/repositories/portal_repository.dart';

/// Error raised by [PortalService]; carries a machine-readable [code] the
/// controller maps to an HTTP status.
class PortalServiceException implements Exception {
  const PortalServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PortalServiceException($code): $message';
}

/// Public portal / QR self-service use-cases (Proto Contract Book §3.8).
///
/// Tokens are opaque random strings stored in `portal_tokens` with an optional
/// expiry. Student login secrets are stored as SHA-256 digests (never in
/// clear), and successful logins receive a short-lived portal JWT signed by
/// the same `JWT_SECRET` as the staff API but carrying `portal: true` and the
/// token scope, so the portal endpoints can be kept outside the staff RBAC
/// matrix while still being authenticated.
class PortalService {
  PortalService(
    this._repo,
    this._audit,
    this._changeLog,
  );

  final PortalRepository _repo;
  final AuditService _audit;
  final ChangeLogService _changeLog;

  static const _tokenAlphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  // ---------------------------------------------------------- staff side --

  /// Generate a QR token for a batch/business/student (Owner/Admin action –
  /// enforced by the admin controller, not the public one).
  StudentToken generateToken({
    required int businessId,
    int? studentId,
    int? batchId,
    String type = 'batch',
    Duration lifetime = const Duration(days: 365),
    required int actorId,
  }) {
    final tokenValue = _randomToken(32);
    final created = _repo.createToken(StudentToken(
      businessId: businessId,
      studentId: studentId,
      batchId: batchId,
      token: tokenValue,
      type: type == 'student' ? 'student' : (type == 'business' ? 'business' : 'batch'),
      expiresAt: DateTime.now().toUtc().add(lifetime),
      isActive: true,
    ));
    _audit.logAction(
      userId: actorId,
      entityType: 'portal_token',
      entityId: created.id ?? 0,
      action: 'create',
      newValue: 'type=${created.type}; student=${created.studentId}; '
          'batch=${created.batchId}',
      businessId: businessId,
    );
    _changeLog.recordChange(
      entityType: 'portal_token',
      entityId: created.id ?? 0,
      operation: ChangeOperation.insert,
      payload: created.toJson(),
      businessId: businessId,
    );
    return created;
  }

  /// Set/rotate the login secret of a student (digest stored, clear-text
  /// returned is impossible – the teacher hands the secret to the student).
  void setStudentSecret({
    required int businessId,
    required String studentCode,
    required String secret,
    required int actorId,
  }) {
    final student = _repo.findStudentByCode(businessId, studentCode);
    if (student == null) {
      throw const PortalServiceException('not_found', 'Student not found');
    }
    final digest = HmacHelper.sha256Hex('$businessId:$studentCode:$secret');
    // Parameterised UPDATE.
    _repo.updateStudentSecret(businessId, studentCode, digest);
    _audit.logAction(
      userId: actorId,
      entityType: 'student',
      entityId: student['id'] as int,
      action: 'update',
      fieldName: 'secret_hash',
      businessId: businessId,
    );
  }

  // --------------------------------------------------------- public side --

  /// List the student codes visible through a portal token.
  List<String> listStudentIds(String tokenValue) {
    final token = _requireValidToken(tokenValue);
    return _repo.studentIdsFor(token);
  }

  /// Student login: `{student_id, secret}` → portal JWT + profile.
  ({String token, Map<String, Object?> profile}) login({
    required String tokenValue,
    required String studentCode,
    required String secret,
  }) {
    final token = _requireValidToken(tokenValue);
    final student = _repo.findStudentByCode(token.businessId, studentCode);
    if (student == null) {
      throw const PortalServiceException(
          'invalid_credentials', 'Unknown student');
    }
    if (!_repo.studentVisibleThrough(token, student['id'] as int)) {
      throw const PortalServiceException(
          'forbidden', 'Student not in this portal scope');
    }
    final storedDigest = student['secret_hash'] as String?;
    final provided =
        HmacHelper.sha256Hex('${token.businessId}:$studentCode:$secret');
    if (storedDigest == null ||
        !HmacHelper.secureEquals(storedDigest, provided)) {
      throw const PortalServiceException(
          'invalid_credentials', 'Invalid student secret');
    }

    final jwt = JwtHelper.sign(
      userId: student['id'] as int,
      roleId: 0, // portal role: outside the staff matrix by design
      businessId: token.businessId,
      lifetime: const Duration(hours: 2),
      extra: {
        'portal': true,
        'portalToken': tokenValue,
        'studentCode': studentCode,
      },
    );
    return (token: jwt, profile: profileFor(student, token));
  }

  /// Profile for an authenticated portal session (portal JWT in `extra`).
  Map<String, Object?>? profileFromJwt(JwtPayload jwt) {
    if (jwt.extra['portal'] != true) return null;
    final tokenValue = jwt.extra['portalToken'] as String?;
    if (tokenValue == null) return null;
    final token = _requireValidToken(tokenValue);
    final student = _repo.findStudentByCode(
        token.businessId, jwt.extra['studentCode'] as String? ?? '');
    if (student == null) return null;
    return profileFor(student, token);
  }

  /// Direct QR scan: returns only non-sensitive fields (Proto Book §3.8).
  Map<String, Object?>? qrProfile(String tokenValue, {int? studentId}) {
    final token = _requireValidToken(tokenValue);
    final scope = _repo.studentIdsFor(token);
    if (scope.isEmpty) return null;

    // A student-scoped token exposes that student directly.
    final codes = token.type == 'student' ? scope : scope.take(1).toList();
    if (codes.isEmpty) return null;
    final student = _repo.findStudentByCode(token.businessId, codes.first);
    if (student == null) return null;
    final fees = _repo.feeSummary(token.businessId, codes.first);
    return {
      'name': student['name'],
      // Non-sensitive only: no phone, no secret, no internal IDs beyond the
      // public student code.
      'student_id': student['student_code'],
      'total_fee': fees.totalFee,
      'paid': fees.paid,
      'due': fees.due,
    };
  }

  /// Full profile shape shared by login + portal/me.
  Map<String, Object?> profileFor(
      Map<String, Object?> student, StudentToken token) {
    final code = student['student_code'] as String;
    final fees = _repo.feeSummary(token.businessId, code);
    return {
      'name': student['name'],
      'student_id': code,
      'batch': student['batch_id'],
      'total_fee': fees.totalFee,
      'paid': fees.paid,
      'due': fees.due,
      'attendance_percent':
          _repo.attendancePercent(token.businessId, student['id'] as int),
    };
  }

  // ----------------------------------------------------------- internals --

  StudentToken _requireValidToken(String tokenValue) {
    final token = _repo.findToken(tokenValue);
    if (token == null || !token.isActive) {
      throw const PortalServiceException('invalid_token', 'Invalid token');
    }
    final expires = token.expiresAt;
    if (expires != null && DateTime.now().toUtc().isAfter(expires)) {
      throw const PortalServiceException('invalid_token', 'Token expired');
    }
    return token;
  }

  static String _randomToken(int length) {
    final random = Random.secure();
    return List.generate(length,
        (_) => _tokenAlphabet[random.nextInt(_tokenAlphabet.length)]).join();
  }
}
