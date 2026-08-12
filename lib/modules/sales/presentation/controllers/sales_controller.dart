import 'dart:convert';

import 'package:shelf/shelf.dart';
import '../../../../core/utils/request_extensions.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/sales_service.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/sale_payment.dart';

/// REST controller for the Sales & POS module (Proto Contract Book Ã‚Â§3.2).
///
/// Routes (mounted under `/api/v1/sales/`):
///  * `POST   /`               Ã¢â‚¬â€œ create sale            (`sale:create`)
///  * `GET    /`               Ã¢â‚¬â€œ list sales             (`sale:read`)
///  * `GET    /<id>`           Ã¢â‚¬â€œ sale detail            (`sale:read`)
///  * `PUT    /<id>`           Ã¢â‚¬â€œ update draft/hold sale (`sale:update`)
///  * `DELETE /<id>`           Ã¢â‚¬â€œ cancel sale            (`sale:delete`)
///  * `POST   /<id>/return`    Ã¢â‚¬â€œ process return         (`sale:return`)
class SalesController {
  SalesController(this._service, this._checker);

  final SalesService _service;
  final PermissionChecker _checker;

  Router get router {
    final r = Router();
    r.post('/', requirePermission(_checker, 'sale', 'create')(_create));
    r.get('/', requirePermission(_checker, 'sale', 'read')(_list));
    r.get('/<id|[0-9]+>',
        requirePermission(_checker, 'sale', 'read')(
            (req) => _get(req, req.requiredParam('id'))));
    r.put('/<id|[0-9]+>',
        requirePermission(_checker, 'sale', 'update')(
            (req) => _update(req, req.requiredParam('id'))));
    r.delete('/<id|[0-9]+>',
        requirePermission(_checker, 'sale', 'delete')(
            (req) => _delete(req, req.requiredParam('id'))));
    r.post('/<id|[0-9]+>/return',
        requirePermission(_checker, 'sale', 'return')(
            (req) => _return(req, req.requiredParam('id'))));
    r.post('/<id|[0-9]+>/payments',
        requirePermission(_checker, 'payment', 'create')(
            (req) => _receivePayment(req, req.requiredParam('id'))));
    return r;
  }

  Future<Response> _create(Request request) async {
    final auth = authContextOf(request)!;
    final body = await _jsonBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');

    final rawItems = body['items'];
    if (rawItems is! List || rawItems.isEmpty) {
      return ResponseEnvelope.badRequest('Sale must contain an items array');
    }
    double d(Object? v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    final items = <SaleItem>[
      for (final raw in rawItems)
        if (raw is Map)
          SaleItem(
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
    final payments = <SalePayment>[
      if (rawPayments is List)
        for (final raw in rawPayments)
          if (raw is Map)
            SalePayment(
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
      final detail = await _service.createSale(
        businessId: auth.businessId,
        customerId: (body['customer_id'] as num?)?.toInt() ??
            (body['customerId'] as num?)?.toInt(),
        warehouseId: warehouseId,
        saleDate: DateTime.tryParse('${body['sale_date'] ?? body['saleDate'] ?? ''}'),
        saleType: (body['sale_type'] ?? body['saleType'] ?? 'POS').toString(),
        discountPercent: d(body['discount_percent'] ?? body['discountPercent']),
        taxPercent: d(body['tax_percent'] ?? body['taxPercent']),
        note: body['note']?.toString(),
        status: (body['status'] ?? 'Completed').toString(),
        items: items,
        payments: payments,
        actorId: auth.userId,
      );
      return ResponseEnvelope.created(detail.toJson());
    } on SalesServiceException catch (e) {
      return _mapError(e);
    }
  }

  Future<Response> _list(Request request) async {
    final auth = authContextOf(request)!;
    final q = request.url.queryParameters;
    final sales = await _service.listSales(
      auth.businessId,
      customerId: int.tryParse(q['customer_id'] ?? q['customerId'] ?? ''),
      status: q['status'],
      paymentStatus: q['payment_status'] ?? q['paymentStatus'],
      saleType: q['sale_type'] ?? q['saleType'],
      fromDate: q['from_date'] ?? q['fromDate'],
      toDate: q['to_date'] ?? q['toDate'],
      limit: int.tryParse(q['limit'] ?? '') ?? 50,
      offset: int.tryParse(q['offset'] ?? '') ?? 0,
    );
    return ResponseEnvelope.success(sales.map((s) => s.toJson()).toList());
  }

  Future<Response> _get(Request request, String id) async {
    final auth = authContextOf(request)!;
    final detail = await _service.getSale(auth.businessId, int.parse(id));
    if (detail == null) return ResponseEnvelope.notFound('Sale not found');
    return ResponseEnvelope.success(detail.toJson());
  }

  Future<Response> _update(Request request, String id) async {
    final auth = authContextOf(request)!;
    final body = await _jsonBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');
    try {
      final sale = await _service.updateSale(
        businessId: auth.businessId,
        id: int.parse(id),
        saleType: (body['sale_type'] ?? body['saleType'])?.toString(),
        warehouseId: (body['warehouse_id'] as num?)?.toInt() ??
            (body['warehouseId'] as num?)?.toInt(),
        status: body['status']?.toString(),
        note: body['note']?.toString(),
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(sale.toJson());
    } on SalesServiceException catch (e) {
      return _mapError(e);
    }
  }

  Future<Response> _delete(Request request, String id) async {
    final auth = authContextOf(request)!;
    try {
      await _service.deleteSale(
        businessId: auth.businessId,
        id: int.parse(id),
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(null, message: 'Sale cancelled');
    } on SalesServiceException catch (e) {
      return _mapError(e);
    }
  }

  Future<Response> _return(Request request, String id) async {
    final auth = authContextOf(request)!;
    final body = await _jsonBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');
    double d(Object? v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    try {
      final saleReturn = await _service.processReturn(
        businessId: auth.businessId,
        saleId: int.parse(id),
        returnDate:
            DateTime.tryParse('${body['return_date'] ?? body['returnDate'] ?? ''}'),
        reason: body['reason']?.toString(),
        restock: body['restock'] == true,
        refundAmount: d(body['refund_amount'] ?? body['refundAmount']),
        refundMethod: (body['refund_method'] ?? body['refundMethod'])?.toString(),
        actorId: auth.userId,
      );
      return ResponseEnvelope.created(saleReturn.toJson());
    } on SalesServiceException catch (e) {
      return _mapError(e);
    }
  }

  /// Record a due-collection payment against a Completed sale
  /// (Event Catalog §3.1 – `PaymentReceived`, Proto Contract Book §3.2).
  Future<Response> _receivePayment(Request request, String id) async {
    final auth = authContextOf(request)!;
    final body = await _jsonBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');
    double d(Object? v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    final amount = d(body['amount']);
    if (amount <= 0) {
      return ResponseEnvelope.badRequest('amount is required');
    }
    try {
      final payment = await _service.receivePayment(
        businessId: auth.businessId,
        saleId: int.parse(id),
        paymentDate:
            DateTime.tryParse('${body['payment_date'] ?? body['paymentDate'] ?? ''}'),
        paymentMethod: (body['payment_method'] ?? body['paymentMethod'] ?? 'Cash')
            .toString(),
        amount: amount,
        reference: body['reference']?.toString(),
        actorId: auth.userId,
      );
      return ResponseEnvelope.created(payment.toJson());
    } on SalesServiceException catch (e) {
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

  Response _mapError(SalesServiceException e) {
    switch (e.code) {
      case 'not_found':
        return ResponseEnvelope.notFound(e.message);
      case 'insufficient_stock':
        return ResponseEnvelope.conflict(e.message);
      case 'already_returned':
      case 'not_cancellable':
      case 'not_editable':
      case 'overpayment':
        return ResponseEnvelope.conflict(e.message);
      default:
        return ResponseEnvelope.badRequest(e.message);
    }
  }
}
