import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/category_service.dart' show ProductServiceException;
import '../../application/services/unit_service.dart';

class UnitController {
  UnitController(this._service, this._checker);

  final UnitService _service;
  final PermissionChecker _checker;

  Router get router {
    final r = Router();
    r.get('/', requirePermission(_checker, 'unit', 'read')(_list));
    r.get('/<id|[0-9]+>', (req) => _get(req, req.requiredParam('id')));
    r.post('/', requirePermission(_checker, 'unit', 'create')(_create));
    r.put('/<id|[0-9]+>', (req) => _update(req, req.requiredParam('id')));
    r.delete('/<id|[0-9]+>', (req) => _delete(req, req.requiredParam('id')));
    return r;
  }

  Future<Response> _list(Request request) async {
    final auth = authContextOf(request)!;
    final items = await _service.list(auth.businessId);
    return ResponseEnvelope.success(items.map((u) => u.toJson()).toList());
  }

  Future<Response> _get(Request request, String id) async {
    final auth = authContextOf(request)!;
    final u = await _service.getById(int.parse(id));
    if (u == null || u.businessId != auth.businessId) {
      return ResponseEnvelope.notFound('Unit not found');
    }
    return ResponseEnvelope.success(u.toJson());
  }

  Future<Response> _create(Request request) async {
    final auth = authContextOf(request)!;
    Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return ResponseEnvelope.badRequest('Invalid JSON body');
    }
    try {
      final u = await _service.create(
        businessId: auth.businessId,
        name: body['name'] as String,
        abbreviation: body['abbreviation'] as String,
        actorId: auth.userId,
      );
      return ResponseEnvelope.created(u.toJson());
    } on ProductServiceException catch (e) {
      return ResponseEnvelope.error(e.code, e.message,
          status: e.code == 'duplicate' ? 409 : 404);
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
      final u = await _service.update(
        id: int.parse(id),
        businessId: auth.businessId,
        name: body['name'] as String?,
        abbreviation: body['abbreviation'] as String?,
        isActive: body['isActive'] as bool?,
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(u.toJson());
    } on ProductServiceException catch (e) {
      return ResponseEnvelope.error(e.code, e.message, status: 404);
    }
  }

  Future<Response> _delete(Request request, String id) async {
    final auth = authContextOf(request)!;
    try {
      await _service.delete(
        id: int.parse(id),
        businessId: auth.businessId,
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(null, message: 'Unit deactivated');
    } on ProductServiceException catch (e) {
      return ResponseEnvelope.error(e.code, e.message, status: 404);
    }
  }
}
