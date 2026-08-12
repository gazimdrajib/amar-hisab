import 'dart:convert';

import 'package:shelf/shelf.dart';
import '../../../../core/utils/request_extensions.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/inventory_service.dart';
import '../../application/services/warehouse_service.dart' show InventoryServiceException;

/// Inventory endpoints under `/inventory`.
///
/// * `GET  /inventory/product/<productId>`   Ã¢â‚¬â€œ stock per warehouse
/// * `GET  /inventory/warehouse/<warehouseId>` Ã¢â‚¬â€œ stock snapshot
/// * `GET  /inventory/batches/<productId>`    Ã¢â‚¬â€œ batch list
/// * `GET  /inventory/movements/<productId>`  Ã¢â‚¬â€œ movement history
/// * `POST /inventory/add` / `deduct` / `transfer` / `adjust` Ã¢â‚¬â€œ mutations
class InventoryController {
  InventoryController(this._service, this._checker);

  final InventoryService _service;
  final PermissionChecker _checker;

  Router get router {
    final r = Router();
    r.get('/product/<productId|[0-9]+>',
        requirePermission(_checker, 'inventory', 'read')((req) => _stockByProduct(req, req.requiredParam('productId'))));
    r.get('/warehouse/<warehouseId|[0-9]+>',
        requirePermission(_checker, 'inventory', 'read')((req) => _stockByWarehouse(req, req.requiredParam('warehouseId'))));
    r.get('/batches/<productId|[0-9]+>',
        requirePermission(_checker, 'batch', 'read')((req) => _batches(req, req.requiredParam('productId'))));
    r.get('/movements/<productId|[0-9]+>',
        requirePermission(_checker, 'inventory', 'read')((req) => _movements(req, req.requiredParam('productId'))));
    r.post('/add',
        requirePermission(_checker, 'inventory', 'adjust')(_addStock));
    r.post('/deduct',
        requirePermission(_checker, 'inventory', 'adjust')(_deductStock));
    r.post('/transfer',
        requirePermission(_checker, 'inventory', 'transfer')(_transferStock));
    r.post('/adjust',
        requirePermission(_checker, 'inventory', 'adjust')(_adjustStock));
    return r;
  }

  // -- Queries ----------------------------------------------------------------

  Future<Response> _stockByProduct(Request request, String productId) async {
    final auth = authContextOf(request)!;
    final list = await _service.stockForProduct(
        auth.businessId, int.parse(productId));
    return ResponseEnvelope.success(list.map((s) => s.toJson()).toList());
  }

  Future<Response> _stockByWarehouse(
      Request request, String warehouseId) async {
    final auth = authContextOf(request)!;
    final list = await _service.stockForWarehouse(
        auth.businessId, int.parse(warehouseId));
    return ResponseEnvelope.success(list.map((s) => s.toJson()).toList());
  }

  Future<Response> _batches(Request request, String productId) async {
    final auth = authContextOf(request)!;
    final warehouseId =
        int.tryParse(request.url.queryParameters['warehouseId'] ?? '');
    final list = await _service.batchesFor(
      auth.businessId,
      int.parse(productId),
      warehouseId: warehouseId,
    );
    return ResponseEnvelope.success(list.map((b) => b.toJson()).toList());
  }

  Future<Response> _movements(Request request, String productId) async {
    final auth = authContextOf(request)!;
    final list = await _service.productHistory(
        auth.businessId, int.parse(productId));
    return ResponseEnvelope.success(list.map((m) => m.toJson()).toList());
  }

  // -- Mutations --------------------------------------------------------------

  Future<Response> _addStock(Request request) async {
    final auth = authContextOf(request)!;
    final body = await _decodeBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');
    try {
      final stock = await _service.addStock(
        businessId: auth.businessId,
        productId: body['productId'] as int,
        warehouseId: body['warehouseId'] as int,
        quantity: (body['quantity'] as num).toDouble(),
        batchNumber: body['batchNumber'] as String?,
        purchasePrice: (body['purchasePrice'] as num?)?.toDouble() ?? 0,
        expiryDate: body['expiryDate'] == null
            ? null
            : DateTime.tryParse(body['expiryDate'] as String),
        batchId: body['batchId'] as int?,
        referenceType: body['referenceType'] as String?,
        referenceId: body['referenceId'] as int?,
        note: body['note'] as String?,
        actorId: auth.userId,
      );
      return ResponseEnvelope.created(stock.toJson());
    } on InventoryServiceException catch (e) {
      return _serviceError(e);
    }
  }

  Future<Response> _deductStock(Request request) async {
    final auth = authContextOf(request)!;
    final body = await _decodeBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');
    try {
      final stock = await _service.deductStock(
        businessId: auth.businessId,
        productId: body['productId'] as int,
        warehouseId: body['warehouseId'] as int,
        quantity: (body['quantity'] as num).toDouble(),
        movementType: (body['movementType'] as String?) ?? 'deduct',
        referenceType: body['referenceType'] as String?,
        referenceId: body['referenceId'] as int?,
        note: body['note'] as String?,
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(stock.toJson());
    } on InventoryServiceException catch (e) {
      return _serviceError(e);
    }
  }

  Future<Response> _transferStock(Request request) async {
    final auth = authContextOf(request)!;
    final body = await _decodeBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');
    try {
      await _service.transferStock(
        businessId: auth.businessId,
        productId: body['productId'] as int,
        fromWarehouseId: body['fromWarehouseId'] as int,
        toWarehouseId: body['toWarehouseId'] as int,
        quantity: (body['quantity'] as num).toDouble(),
        note: body['note'] as String?,
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(null, message: 'Transfer completed');
    } on InventoryServiceException catch (e) {
      return _serviceError(e);
    }
  }

  Future<Response> _adjustStock(Request request) async {
    final auth = authContextOf(request)!;
    final body = await _decodeBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');
    try {
      final stock = await _service.adjustStock(
        businessId: auth.businessId,
        productId: body['productId'] as int,
        warehouseId: body['warehouseId'] as int,
        newQuantity: (body['newQuantity'] as num).toDouble(),
        note: body['note'] as String?,
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(stock.toJson());
    } on InventoryServiceException catch (e) {
      return _serviceError(e);
    }
  }

  // -- Helpers ----------------------------------------------------------------

  Future<Map<String, dynamic>?> _decodeBody(Request request) async {
    try {
      return jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Response _serviceError(InventoryServiceException e) {
    int status;
    switch (e.code) {
      case 'not_found':
      case 'batch_not_found':
        status = 404;
        break;
      case 'duplicate':
        status = 409;
        break;
      case 'insufficient_stock':
        status = 422;
        break;
      default:
        status = 400;
    }
    return ResponseEnvelope.error(e.code, e.message, status: status);
  }
}
