import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/brand_service.dart';
import '../../application/services/category_service.dart' show ProductServiceException;

class BrandController {
  BrandController(this._service, this._checker);

  final BrandService _service;
  final PermissionChecker _checker;

  Router get router {
    final r = Router();
    r.get('/', requirePermission(_checker, 'brand', 'read')(_list));
    r.get('/<id|[0-9]+>', (req) => _get(req, req.requiredParam('id')));
    r.post('/', requirePermission(_checker, 'brand', 'create')(_create));
    r.put('/<id|[0-9]+>', (req) => _update(req, req.requiredParam('id')));
    r.delete('/<id|[0-9]+>', (req) => _delete(req, req.requiredParam('id')));
    return r;
  }

  Future<Response> _list(Request request) async {
    final auth = authContextOf(request)!;
    final items = await _service.list(auth.businessId);
    return ResponseEnvelope.success(items.map((b) => b.toJson()).toList());
  }

  Future<Response> _get(Request request, String id) async {
    final auth = authContextOf(request)!;
    final b = await _service.getById(int.parse(id));
    if (b == null || b.businessId != auth.businessId) {
      return ResponseEnvelope.notFound('Brand not found');
    }
    return ResponseEnvelope.success(b.toJson());
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
      final b = await _service.create(
        businessId: auth.businessId,
        name: body['name'] as String,
        description: body['description'] as String?,
        actorId: auth.userId,
      );
      return ResponseEnvelope.created(b.toJson());
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
      final b = await _service.update(
        id: int.parse(id),
        businessId: auth.businessId,
        name: body['name'] as String?,
        description: body['description'] as String?,
        isActive: body['isActive'] as bool?,
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(b.toJson());
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
      return ResponseEnvelope.success(null, message: 'Brand deactivated');
    } on ProductServiceException catch (e) {
      return ResponseEnvelope.error(e.code, e.message, status: 404);
    }
  }
}
