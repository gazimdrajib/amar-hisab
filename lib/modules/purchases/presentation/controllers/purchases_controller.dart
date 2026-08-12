import 'dart:convert';

import 'package:shelf/shelf.dart';
import '../../../../core/utils/request_extensions.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/purchase_service.dart';
import '../../domain/entities/purchase_item.dart';
import '../../domain/entities/supplier_payment.dart';

/// REST controller for the Purchase module (Proto Contract Book Ã‚Â§3.3).
///
/// Routes (mounted under `/api/v1/purchases/`):
///  * `POST   /`               Ã¢â‚¬â€œ create purchase            (`purchase:create`)
///  * `GET    /`               Ã¢â‚¬â€œ list purchases             (`purchase:read`)
///  * `GET    /<id>`           Ã¢â‚¬â€œ purchase detail            (`purchase:read`)
///  * `PUT    /<id>`           Ã¢â‚¬â€œ update draft/ordered      (`purchase:update`)
///  * `DELETE /<id>`           Ã¢â‚¬â€œ cancel purchase            (`purchase:delete`)
class PurchasesController {
  PurchasesController(this._service, this._checker);

  final PurchaseService _service;
  final PermissionChecker _checker;

  Router get router {
    final r = Router();
    r.post('/', requirePermission(_checker, 'purchase', 'create')(_create));
    r.get('/', requirePermission(_checker, 'purchase', 'read')(_list));
    r.get('/<id|[0-9]+>',
        requirePermission(_checker, 'purchase', 'read')(
            (req) => _get(req, req.requiredParam('id'))));
    r.put('/<id|[0-9]+>',
        requirePermission(_checker, 'purchase', 'update')(
            (req) => _update(req, req.requiredParam('id'))));
    r.delete('/<id|[0-9]+>',
        requirePermission(_checker, 'purchase', 'delete')(
            (req) => _delete(req, req.requiredParam('id'))));
    return r;
  }

  Future<Response> _create(Request request) async {
    final auth = authContextOf(request)!;
    final body = await _jsonBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');

    final rawItems = body['items'];
    if (rawItems is! List || rawItems.isEmpty) {
      return ResponseEnvelope.badRequest('Purchase must contain an items array');
    }
    double d(Object? v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    final items = <PurchaseItem>[
      for (final raw in rawItems)
        if (raw is Map)
          PurchaseItem(
            productId: (raw['product_id'] as num?)?.toInt() ??
                (raw['productId'] as num?)?.toInt() ??
                0,
            quantity: d(raw['quantity']),
            unitPrice: d(raw['unit_price'] ?? raw['unitPrice']),
            discountPercent: d(raw['discount_percent'] ?? raw['discountPercent']),
            taxPercent: d(raw['tax_percent'] ?? raw['taxPercent']),
          ),
    ];
    if (items.any((i) => i.productId == 0)) {
      return ResponseEnvelope.badRequest('Every item requires a product_id');
    }

    final rawPayments = body['payments'];
    final payments = <SupplierPayment>[
      if (rawPayments is List)
        for (final raw in rawPayments)
          if (raw is Map)
            SupplierPayment(
              amount: d(raw['amount']),
              paymentMethod:
                  (raw['payment_method'] ?? raw['paymentMethod'] ?? 'Cash')
                      .toString(),
              reference: raw['reference']?.toString(),
            ),
    ];

    final warehouseId = (body['warehouse_id'] as num?)?.toInt() ??
        (body['warehouseId'] as num?)?.toInt();
    if (warehouseId == null) {
      return ResponseEnvelope.badRequest('warehouse_id is required');
    }

    try {
      final detail = await _service.createPurchase(
        businessId: auth.businessId,
        supplierId: (body['supplier_id'] as num?)?.toInt() ??
            (body['supplierId'] as num?)?.toInt(),
        warehouseId: warehouseId,
        purchaseDate: DateTime.tryParse(
            '${body['purchase_date'] ?? body['purchaseDate'] ?? ''}'),
        discountPercent: d(body['discount_percent'] ?? body['discountPercent']),
        taxPercent: d(body['tax_percent'] ?? body['taxPercent']),
        note: body['note']?.toString(),
        status: (body['status'] ?? 'Received').toString(),
        items: items,
        payments: payments,
        actorId: auth.userId,
      );
      return ResponseEnvelope.created(detail.toJson());
    } on PurchaseServiceException catch (e) {
      return _mapError(e);
    }
  }

  Future<Response> _list(Request request) async {
    final auth = authContextOf(request)!;
    final q = request.url.queryParameters;
    final purchases = await _service.listPurchases(
      auth.businessId,
      supplierId: int.tryParse(q['supplier_id'] ?? q['supplierId'] ?? ''),
      status: q['status'],
      paymentStatus: q['payment_status'] ?? q['paymentStatus'],
      fromDate: q['from_date'] ?? q['fromDate'],
      toDate: q['to_date'] ?? q['toDate'],
      limit: int.tryParse(q['limit'] ?? '') ?? 50,
      offset: int.tryParse(q['offset'] ?? '') ?? 0,
    );
    return ResponseEnvelope.success(
        purchases.map((p) => p.toJson()).toList());
  }

  Future<Response> _get(Request request, String id) async {
    final auth = authContextOf(request)!;
    final detail =
        await _service.getPurchase(auth.businessId, int.parse(id));
    if (detail == null) return ResponseEnvelope.notFound('Purchase not found');
    return ResponseEnvelope.success(detail.toJson());
  }

  Future<Response> _update(Request request, String id) async {
    final auth = authContextOf(request)!;
    final body = await _jsonBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');
    try {
      final purchase = await _service.updatePurchase(
        businessId: auth.businessId,
        id: int.parse(id),
        supplierId: (body['supplier_id'] as num?)?.toInt() ??
            (body['supplierId'] as num?)?.toInt(),
        warehouseId: (body['warehouse_id'] as num?)?.toInt() ??
            (body['warehouseId'] as num?)?.toInt(),
        status: body['status']?.toString(),
        note: body['note']?.toString(),
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(purchase.toJson());
    } on PurchaseServiceException catch (e) {
      return _mapError(e);
    }
  }

  Future<Response> _delete(Request request, String id) async {
    final auth = authContextOf(request)!;
    try {
      await _service.deletePurchase(
        businessId: auth.businessId,
        id: int.parse(id),
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(null, message: 'Purchase cancelled');
    } on PurchaseServiceException catch (e) {
      return _mapError(e);
    }
  }

  // -- Helpers ----------------------------------------------------------------

  Future<Map<String, dynamic>?> _jsonBody(Request request) async {
    try {
      final decoded = jsonDecode(await request.readAsString());
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Response _mapError(PurchaseServiceException e) {
    switch (e.code) {
      case 'not_found':
        return ResponseEnvelope.notFound(e.message);
      case 'not_cancellable':
      case 'not_editable':
      case 'overpayment':
        return ResponseEnvelope.conflict(e.message);
      default:
        return ResponseEnvelope.badRequest(e.message);
    }
  }
}
