import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/category_service.dart' show ProductServiceException;
import '../../application/services/product_service.dart';

class ProductController {
  ProductController(this._service, this._checker);

  final ProductService _service;
  final PermissionChecker _checker;

  Router get router {
    final r = Router();
    r.get('/', requirePermission(_checker, 'product', 'read')(_list));
    r.get('/search/<query>', (req) => _search(req, req.requiredParam('query')));
    r.get('/<id|[0-9]+>', (req) => _get(req, req.requiredParam('id')));
    r.post('/', requirePermission(_checker, 'product', 'create')(_create));
    r.put('/<id|[0-9]+>', (req) => _update(req, req.requiredParam('id')));
    r.delete('/<id|[0-9]+>', (req) => _delete(req, req.requiredParam('id')));
    return r;
  }

  Future<Response> _list(Request request) async {
    final auth = authContextOf(request)!;
    final includeInactive =
        request.url.queryParameters['includeInactive'] == 'true';
    final items =
        await _service.list(auth.businessId, includeInactive: includeInactive);
    return ResponseEnvelope.success(items.map((p) => p.toJson()).toList());
  }

  Future<Response> _search(Request request, String query) async {
    final auth = authContextOf(request)!;
    final items = await _service.search(auth.businessId, query);
    return ResponseEnvelope.success(items.map((p) => p.toJson()).toList());
  }

  Future<Response> _get(Request request, String id) async {
    final auth = authContextOf(request)!;
    final p = await _service.getById(int.parse(id));
    if (p == null || p.businessId != auth.businessId) {
      return ResponseEnvelope.notFound('Product not found');
    }
    return ResponseEnvelope.success(p.toJson());
  }

  Future<Response> _create(Request request) async {
    final auth = authContextOf(request)!;
    Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return ResponseEnvelope.badRequest('Invalid JSON body');
    }
    double parseDouble(String key) => (body[key] as num?)?.toDouble() ?? 0;
    try {
      final p = await _service.create(
        businessId: auth.businessId,
        sku: body['sku'] as String,
        barcode: body['barcode'] as String?,
        name: body['name'] as String,
        description: body['description'] as String?,
        categoryId: body['categoryId'] as int?,
        brandId: body['brandId'] as int?,
        unitId: body['unitId'] as int?,
        purchasePrice: parseDouble('purchasePrice'),
        sellingPrice: parseDouble('sellingPrice'),
        taxRate: parseDouble('taxRate'),
        minStockLevel: parseDouble('minStockLevel'),
        actorId: auth.userId,
      );
      return ResponseEnvelope.created(p.toJson());
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
    double? parseDouble(String key) => (body[key] as num?)?.toDouble();
    try {
      final p = await _service.update(
        id: int.parse(id),
        businessId: auth.businessId,
        sku: body['sku'] as String?,
        barcode: body['barcode'] as String?,
        name: body['name'] as String?,
        description: body['description'] as String?,
        categoryId: body['categoryId'] as int?,
        brandId: body['brandId'] as int?,
        unitId: body['unitId'] as int?,
        purchasePrice: parseDouble('purchasePrice'),
        sellingPrice: parseDouble('sellingPrice'),
        taxRate: parseDouble('taxRate'),
        minStockLevel: parseDouble('minStockLevel'),
        isActive: body['isActive'] as bool?,
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(p.toJson());
    } on ProductServiceException catch (e) {
      return ResponseEnvelope.error(e.code, e.message,
          status: e.code == 'duplicate' ? 409 : 404);
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
      return ResponseEnvelope.success(null, message: 'Product deactivated');
    } on ProductServiceException catch (e) {
      return ResponseEnvelope.error(e.code, e.message, status: 404);
    }
  }
}
