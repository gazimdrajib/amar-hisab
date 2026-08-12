import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/warehouse_service.dart';

class WarehouseController {
  WarehouseController(this._service, this._checker);

  final WarehouseService _service;
  final PermissionChecker _checker;

  Router get router {
    final r = Router();
    r.get('/', requirePermission(_checker, 'warehouse', 'read')(_list));
    r.get('/<id|[0-9]+>', (req) => _get(req, req.requiredParam('id')));
    r.post('/', requirePermission(_checker, 'warehouse', 'create')(_create));
    r.put('/<id|[0-9]+>', (req) => _update(req, req.requiredParam('id')));
    r.delete('/<id|[0-9]+>', (req) => _delete(req, req.requiredParam('id')));
    return r;
  }

  Future<Response> _list(Request request) async {
    final auth = authContextOf(request)!;
    final items = await _service.list(auth.businessId);
    return ResponseEnvelope.success(items.map((w) => w.toJson()).toList());
  }

  Future<Response> _get(Request request, String id) async {
    final auth = authContextOf(request)!;
    final w = await _service.getById(int.parse(id));
    if (w == null || w.businessId != auth.businessId) {
      return ResponseEnvelope.notFound('Warehouse not found');
    }
    return ResponseEnvelope.success(w.toJson());
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
      final w = await _service.create(
        businessId: auth.businessId,
        name: body['name'] as String,
        location: body['location'] as String?,
        actorId: auth.userId,
      );
      return ResponseEnvelope.created(w.toJson());
    } on InventoryServiceException catch (e) {
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
      final w = await _service.update(
        id: int.parse(id),
        businessId: auth.businessId,
        name: body['name'] as String?,
        location: body['location'] as String?,
        isActive: body['isActive'] as bool?,
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(w.toJson());
    } on InventoryServiceException catch (e) {
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
      return ResponseEnvelope.success(null, message: 'Warehouse deactivated');
    } on InventoryServiceException catch (e) {
      return ResponseEnvelope.error(e.code, e.message, status: 404);
    }
  }
}
