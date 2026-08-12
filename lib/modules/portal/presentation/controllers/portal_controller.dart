import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/utils/jwt_helper.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/portal_service.dart';

/// Public portal routes (Proto Contract Book Ã‚Â§3.8).
///
/// These endpoints are UNAUTHENTICATED at the HTTP middleware layer (mounted
/// under `/public/Ã¢â‚¬Â¦`); access is authorised by the opaque portal token in the
/// URL and, for profile access, by the student's own secret or a portal JWT.
///
/// Mounted routes:
///  * `GET  /portal/<token>/students` Ã¢â‚¬â€œ list student IDs for the QR portal
///  * `POST /portal/<token>/login`    Ã¢â‚¬â€œ student ID + secret Ã¢â€ â€™ portal JWT
///  * `GET  /portal/me`               Ã¢â‚¬â€œ profile from portal JWT
///    (`Authorization: Bearer <portal_jwt>`)
///  * `GET  /qr/<token>/profile`      Ã¢â‚¬â€œ direct QR-scan profile (non-sensitive)
class PortalController {
  PortalController(this._service);

  final PortalService _service;

  Router get portalRouter {
    final r = Router();
    r.get('/<token>/students', (req) => _students(req, _pathToken(req)));
    r.post('/<token>/login', (req) => _login(req, _pathToken(req)));
    r.get('/me', _me);
    return r;
  }

  Router get qrRouter {
    final r = Router();
    r.get('/<token>/profile', (req) => _qrProfile(req, _pathToken(req)));
    return r;
  }

  /// Extract the `<token>` path parameter in a way that is independent of
  /// the `shelf_router` version (this project's `shelf@1.4.1` does not
  /// provide `Request.params`; the public portal URL shape is stable:
  /// `/public/portal/<token>/<leaf>` or `/public/qr/<token>/profile`).
  String _pathToken(Request request) {
    final segments = request.requestedUri.pathSegments;
    // segments e.g. [public, portal, <token>, students] or [public, qr, <token>, profile]
    return segments.length >= 3 ? segments[2] : '';
  }

  Response _students(Request request, String token) {
    try {
      final ids = _service.listStudentIds(token);
      return ResponseEnvelope.success({
        'students': [for (final id in ids) {'student_id': id}],
      });
    } on PortalServiceException catch (e) {
      return _failure(e);
    }
  }

  Future<Response> _login(Request request, String token) async {
    final body = await _jsonBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');
    final studentId = body['student_id']?.toString() ?? '';
    final secret = body['secret']?.toString() ?? '';
    if (studentId.isEmpty || secret.isEmpty) {
      return ResponseEnvelope.badRequest('student_id and secret are required');
    }
    try {
      final result = _service.login(
        tokenValue: token,
        studentCode: studentId,
        secret: secret,
      );
      return ResponseEnvelope.success({
        'token': result.token,
        'profile': result.profile,
      });
    } on PortalServiceException catch (e) {
      return _failure(e);
    }
  }

  Response _me(Request request) {
    final header = request.headers['authorization'] ??
        request.headers['Authorization'] ??
        '';
    if (!header.toLowerCase().startsWith('bearer ')) {
      return ResponseEnvelope.unauthorized('Missing portal token');
    }
    final jwt = JwtHelper.verify(header.substring(7).trim());
    if (jwt == null) {
      return ResponseEnvelope.unauthorized('Invalid or expired portal token');
    }
    if (jwt.extra['portal'] != true) {
      return ResponseEnvelope.forbidden('Not a portal token');
    }
    final profile = _service.profileFromJwt(jwt);
    if (profile == null) return ResponseEnvelope.notFound('Profile not found');
    return ResponseEnvelope.success(profile);
  }

  Response _qrProfile(Request request, String token) {
    try {
      final profile = _service.qrProfile(token);
      if (profile == null) {
        return ResponseEnvelope.notFound('Profile not found');
      }
      return ResponseEnvelope.success(profile);
    } on PortalServiceException catch (e) {
      return _failure(e);
    }
  }

  Response _failure(PortalServiceException e) => switch (e.code) {
        'invalid_token' => ResponseEnvelope.notFound(e.message),
        'invalid_credentials' => ResponseEnvelope.unauthorized(e.message),
        'forbidden' => ResponseEnvelope.forbidden(e.message),
        _ => ResponseEnvelope.badRequest(e.message),
      };

  Future<Map<String, dynamic>?> _jsonBody(Request request) async {
    try {
      final raw = await request.readAsString();
      if (raw.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
