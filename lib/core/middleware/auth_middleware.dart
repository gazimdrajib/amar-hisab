import 'package:shelf/shelf.dart';

import '../../monitoring/metrics.dart';
import '../utils/jwt_helper.dart';
import '../utils/response_envelope.dart';

/// Identity extracted from a valid JWT and attached to the request context.
class AuthContext {
  const AuthContext({
    required this.userId,
    required this.roleId,
    required this.businessId,
  });

  final int userId;
  final int roleId;
  final int businessId;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'roleId': roleId,
        'businessId': businessId,
      };
}

/// Request-context key under which the [AuthContext] is stored.
const String authContextKey = 'amar_hisab.auth';

/// Retrieve the authenticated identity from a request (null when the
/// request bypassed auth, e.g. login/setup endpoints).
AuthContext? authContextOf(Request request) =>
    request.context[authContextKey] as AuthContext?;

/// Paths that never require authentication.
bool _isPublic(String path) {
  // `request.url.path` has no leading slash; normalise before comparing.
  final normalized = path.startsWith('/') ? path : '/$path';
  if (normalized == '/health') return true;
  if (normalized == '/metrics') return true;
  if (normalized == '/api/docs' || normalized == '/api/openapi.yaml') {
    return true;
  }
  if (normalized == '/auth/login' || normalized == '/api/v1/auth/login') {
    return true;
  }
  if (normalized.startsWith('/setup/') || normalized == '/setup') return true;
  if (normalized.startsWith('/api/v1/setup/') || normalized == '/api/v1/setup') {
    return true;
  }
  // Public portal & QR self-service (Proto Contract Book §3.8) – the portal
  // token in the URL provides the authorisation, not a staff JWT.
  if (normalized.startsWith('/public/')) return true;
  return false;
}

/// JWT validation middleware.
///
/// Extracts the `Authorization: Bearer <token>` header, verifies the token,
/// and stores an [AuthContext] in the request context under [authContextKey].
/// Public endpoints (`/health`, `/auth/login`, `/setup/*`) are skipped.
/// Returns a 401 envelope when the token is missing or invalid.
Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (_isPublic(request.url.path)) {
        return innerHandler(request);
      }

      final header = request.headers['authorization'] ??
          request.headers['Authorization'];
      if (header == null || !header.toLowerCase().startsWith('bearer ')) {
        MetricsRegistry.instance.inc('errors.unauthorized');
        return ResponseEnvelope.unauthorized('Missing bearer token');
      }

      final token = header.substring(7).trim();
      final payload = JwtHelper.verify(token);
      if (payload == null) {
        MetricsRegistry.instance.inc('errors.unauthorized');
        return ResponseEnvelope.unauthorized('Invalid or expired token');
      }

      final updated = request.change(context: {
        ...request.context,
        authContextKey: AuthContext(
          userId: payload.userId,
          roleId: payload.roleId,
          businessId: payload.businessId,
        ),
      });
      return innerHandler(updated);
    };
  };
}
