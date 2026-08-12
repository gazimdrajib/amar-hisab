import 'dart:convert';

import 'package:shelf/shelf.dart';
import '../../../../core/utils/request_extensions.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/user_service.dart';

/// `/users` endpoints protected by RBAC (`user:read|create|update|delete`).
class UserController {
  UserController(this._service, this._checker);

  final UserService _service;
  final PermissionChecker _checker;

  Router get router {
    final r = Router();
    r.get('/', requirePermission(_checker, 'user', 'read')(_list));
    r.get('/<id|[0-9]+>', (req) => _get(req, req.requiredParam('id')));
    r.post('/', requirePermission(_checker, 'user', 'create')(_create));
    r.put('/<id|[0-9]+>', (req) => _update(req, req.requiredParam('id')));
    r.patch('/<id|[0-9]+>/password',
        requirePermission(_checker, 'user', 'update')((req) => _changePassword(req, req.requiredParam('id'))));
    r.delete('/<id|[0-9]+>', (req) => _delete(req, req.requiredParam('id')));
    return r;
  }

  Future<Response> _list(Request request) async {
    final auth = authContextOf(request)!;
    final includeInactive =
        request.url.queryParameters['includeInactive'] == 'true';
    final users = await _service.list(auth.businessId,
        includeInactive: includeInactive);
    return ResponseEnvelope.success(
        users.map((u) => u.toSafeJson()).toList());
  }

  Future<Response> _get(Request request, String id) async {
    final auth = authContextOf(request)!;
    final user = await _service.getById(int.parse(id));
    if (user == null || user.businessId != auth.businessId) {
      return ResponseEnvelope.notFound('User not found');
    }
    return ResponseEnvelope.success(user.toSafeJson());
  }

  Future<Response> _create(Request request) async {
    final auth = authContextOf(request)!;
    Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return ResponseEnvelope.badRequest('Invalid JSON body');
    }

    final username = body['username'] as String?;
    final password = body['password'] as String?;
    final fullName = body['fullName'] as String?;
    final roleId = body['roleId'] as int?;
    if (username == null || password == null || fullName == null || roleId == null) {
      return ResponseEnvelope.badRequest(
          'username, password, fullName and roleId are required');
    }

    try {
      final actorRoleName = await _actorRoleName(auth);
      final user = await _service.create(
        businessId: auth.businessId,
        username: username,
        password: password,
        fullName: fullName,
        roleId: roleId,
        actorId: auth.userId,
        actorRoleName: actorRoleName,
      );
      return ResponseEnvelope.created(user.toSafeJson());
    } on UserServiceException catch (e) {
      return ResponseEnvelope.error(e.code, e.message,
          status: _statusFor(e.code));
    }
  }

  Future<Response> _update(Request request, String id) async {
    final auth = authContextOf(request)!;
    Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return ResponseEnvelope.badRequest('Invalid JSON body');
    }
    try {
      final actorRoleName = await _actorRoleName(auth);
      final user = await _service.update(
        id: int.parse(id),
        username: body['username'] as String?,
        fullName: body['fullName'] as String?,
        roleId: body['roleId'] as int?,
        isActive: body['isActive'] as bool?,
        actorId: auth.userId,
        actorRoleName: actorRoleName,
        actorBusinessId: auth.businessId,
      );
      return ResponseEnvelope.success(user.toSafeJson());
    } on UserServiceException catch (e) {
      return ResponseEnvelope.error(e.code, e.message,
          status: _statusFor(e.code));
    }
  }

  Future<Response> _changePassword(Request request, String id) async {
    final auth = authContextOf(request)!;
    Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return ResponseEnvelope.badRequest('Invalid JSON body');
    }
    final newPassword = body['newPassword'] as String?;
    if (newPassword == null || newPassword.isEmpty) {
      return ResponseEnvelope.badRequest('newPassword is required');
    }
    try {
      await _service.changePassword(
        id: int.parse(id),
        newPassword: newPassword,
        actorId: auth.userId,
        actorBusinessId: auth.businessId,
      );
      return ResponseEnvelope.success(null, message: 'Password updated');
    } on UserServiceException catch (e) {
      return ResponseEnvelope.error(e.code, e.message,
          status: _statusFor(e.code));
    }
  }

  Future<Response> _delete(Request request, String id) async {
    final auth = authContextOf(request)!;
    try {
      final actorRoleName = await _actorRoleName(auth);
      await _service.delete(
        id: int.parse(id),
        actorId: auth.userId,
        actorRoleName: actorRoleName,
        actorBusinessId: auth.businessId,
      );
      return ResponseEnvelope.success(null, message: 'User deactivated');
    } on UserServiceException catch (e) {
      return ResponseEnvelope.error(e.code, e.message,
          status: _statusFor(e.code));
    }
  }

  // Resolve the actor's role name for Owner-assignment guard logic.
  Future<String> _actorRoleName(AuthContext auth) async {
    final user = await _service.getById(auth.userId);
    return user?.roleName ?? '';
  }

  int _statusFor(String code) {
    switch (code) {
      case 'not_found':
        return 404;
      case 'forbidden_role_assignment':
      case 'owner_protected':
      case 'cross_business':
      case 'self_delete':
        return 403;
      case 'username_taken':
        return 409;
      default:
        return 400;
    }
  }
}
