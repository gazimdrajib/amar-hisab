import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/auth_service.dart';

/// Authentication endpoints: `/auth/login`, `/auth/me`.
///
/// `login` is public (auth middleware skips it). `me` requires a valid JWT
/// provided by [authMiddleware]'s context.
class AuthController {
  AuthController(this._authService, this._permissionChecker);

  final AuthService _authService;
  final PermissionChecker _permissionChecker;

  Router get router {
    final r = Router();
    r.post('/login', _login);
    r.get('/me', _me);
    return r;
  }

  Future<Response> _login(Request request) async {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return ResponseEnvelope.badRequest('Invalid JSON body');
    }

    final username = body['username'] as String?;
    final password = body['password'] as String?;
    final businessId = body['businessId'] as int? ?? 1;

    if (username == null || username.isEmpty || password == null) {
      return ResponseEnvelope.badRequest('username and password are required');
    }

    final result = await _authService.login(
      businessId: businessId,
      username: username,
      password: password,
    );
    if (result == null) {
      return ResponseEnvelope.unauthorized('Invalid credentials');
    }

    return ResponseEnvelope.success({
      'token': result.token,
      'user': result.user.toSafeJson(),
      'permissions':
          _permissionChecker.permissionsForRole(result.user.roleId).toList(),
    }, message: 'Login successful');
  }

  Future<Response> _me(Request request) async {
    final auth = authContextOf(request);
    if (auth == null) return ResponseEnvelope.unauthorized();

    final user = await _authService.me(auth.userId);
    if (user == null) return ResponseEnvelope.notFound('User not found');

    return ResponseEnvelope.success({
      'user': user.toSafeJson(),
      'permissions':
          _permissionChecker.permissionsForRole(user.roleId).toList(),
    });
  }
}
