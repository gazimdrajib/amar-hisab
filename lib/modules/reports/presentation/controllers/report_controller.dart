import 'package:shelf/shelf.dart';
import '../../../../core/utils/request_extensions.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/report_export_service.dart';
import '../../application/services/report_service.dart';
import '../../domain/entities/report_table.dart';

/// REST controller for the Reports module (Architecture Book Ã‚Â§14.7).
///
/// Routes (mounted under `/api/v1/reports/`):
///  * `GET /sales`                          Ã¢â‚¬â€œ sales report        (`report:sales`)
///  * `GET /purchases`                      Ã¢â‚¬â€œ purchase report     (`report:purchases`)
///  * `GET /inventory`                      Ã¢â‚¬â€œ inventory report    (`report:inventory`)
///  * `GET /financial`                      Ã¢â‚¬â€œ financial report    (`report:financial`)
///      - `?type=profit-loss&from&to`       Ã¢â‚¬â€œ profit & loss
///      - `?type=balance-sheet&as_of_date`  Ã¢â‚¬â€œ balance sheet
///      - `?type=trial-balance&as_of_date`  Ã¢â‚¬â€œ trial balance (default)
///  * `GET /<report>/export/<format>`       Ã¢â‚¬â€œ Excel/PDF export    (`report:export`)
///
/// Every read returns the standard envelope `{success, data}`; exports return
/// raw `application/vndÃ¢â‚¬Â¦sheet` / `application/pdf` bytes with
/// `Content-Disposition: attachment`.
class ReportController {
  ReportController(this._service, this._exportService, this._checker);

  final ReportService _service;
  final ReportExportService _exportService;
  final PermissionChecker _checker;

  Router get router {
    final r = Router();
    r.get('/sales', requirePermission(_checker, 'report', 'sales')(_sales));
    r.get('/purchases',
        requirePermission(_checker, 'report', 'purchases')(_purchases));
    r.get('/inventory',
        requirePermission(_checker, 'report', 'inventory')(_inventory));
    r.get('/financial',
        requirePermission(_checker, 'report', 'financial')(_financial));
    r.get(
        '/<report|sales|purchases|inventory|financial>/export/'
        '<format|excel|pdf>',
        requirePermission(_checker, 'report', 'export')(
          (req) => _export(req, req.requiredParam('report'), req.requiredParam('format')),
        ));
    return r;
  }

  // -- JSON report endpoints -------------------------------------------------

  Future<Response> _sales(Request request) async {
    final auth = authContextOf(request)!;
    final q = request.url.queryParameters;
    final result = await _service.salesReport(
      auth.businessId,
      from: _fromParam(q),
      to: _toParam(q),
      customerId: _intParam(q, 'customer_id', 'customerId'),
      productId: _intParam(q, 'product_id', 'productId'),
    );
    return ResponseEnvelope.success(result.toJson());
  }

  Future<Response> _purchases(Request request) async {
    final auth = authContextOf(request)!;
    final q = request.url.queryParameters;
    final result = await _service.purchaseReport(
      auth.businessId,
      from: _fromParam(q),
      to: _toParam(q),
      supplierId: _intParam(q, 'supplier_id', 'supplierId'),
      productId: _intParam(q, 'product_id', 'productId'),
    );
    return ResponseEnvelope.success(result.toJson());
  }

  Future<Response> _inventory(Request request) async {
    final auth = authContextOf(request)!;
    final q = request.url.queryParameters;
    final result = await _service.inventoryReport(
      auth.businessId,
      warehouseId: _intParam(q, 'warehouse_id', 'warehouseId'),
      productId: _intParam(q, 'product_id', 'productId'),
    );
    return ResponseEnvelope.success(result.toJson());
  }

  Future<Response> _financial(Request request) async {
    final auth = authContextOf(request)!;
    final q = request.url.queryParameters;
    final type = q['type'] ?? 'trial-balance';
    switch (type) {
      case 'profit-loss':
        final result = await _service.profitLossReport(
            auth.businessId, _fromParam(q), _toParam(q));
        return ResponseEnvelope.success(result.toJson());
      case 'balance-sheet':
        final result = await _service.balanceSheetReport(
            auth.businessId, _asOfParam(q));
        return ResponseEnvelope.success(result.toJson());
      case 'trial-balance':
        final result = await _service.trialBalanceReport(
            auth.businessId, _asOfParam(q));
        return ResponseEnvelope.success(result.toJson());
      default:
        return ResponseEnvelope.badRequest(
            "Unknown financial report type '$type' "
            '(expected profit-loss | balance-sheet | trial-balance)');
    }
  }

  // -- Export endpoint ---------------------------------------------------------

  Future<Response> _export(
      Request request, String report, String format) async {
    final auth = authContextOf(request)!;
    final q = request.url.queryParameters;

    // Rebuild the same projection as the JSON endpoint, then flatten it into
    // columns + rows + a summary block for the export provider.
    late String reportType;
    late String title;
    late List<ReportColumn> columns;
    late List<Map<String, dynamic>> rows;
    late List<SummaryItem> summary;

    switch (report) {
      case 'sales':
        final r = await _service.salesReport(
          auth.businessId,
          from: _fromParam(q),
          to: _toParam(q),
          customerId: _intParam(q, 'customer_id', 'customerId'),
          productId: _intParam(q, 'product_id', 'productId'),
        );
        reportType = 'sales';
        title = 'Sales Report';
        columns = r.table.columns;
        rows = r.table.rows;
        summary = r.summary;
      case 'purchases':
        final r = await _service.purchaseReport(
          auth.businessId,
          from: _fromParam(q),
          to: _toParam(q),
          supplierId: _intParam(q, 'supplier_id', 'supplierId'),
          productId: _intParam(q, 'product_id', 'productId'),
        );
        reportType = 'purchases';
        title = 'Purchase Report';
        columns = r.table.columns;
        rows = r.table.rows;
        summary = r.summary;
      case 'inventory':
        final r = await _service.inventoryReport(
          auth.businessId,
          warehouseId: _intParam(q, 'warehouse_id', 'warehouseId'),
          productId: _intParam(q, 'product_id', 'productId'),
        );
        reportType = 'inventory';
        title = 'Inventory Report';
        columns = r.table.columns;
        rows = r.table.rows;
        summary = r.summary;
      case 'financial':
        final type = q['type'] ?? 'trial-balance';
        reportType = 'financial_$type';
        switch (type) {
          case 'profit-loss':
            final r = await _service.profitLossReport(
                auth.businessId, _fromParam(q), _toParam(q));
            title = 'Profit & Loss';
            columns = const [];
            rows = const [];
            summary = r.summary;
          case 'balance-sheet':
            final r = await _service.balanceSheetReport(
                auth.businessId, _asOfParam(q));
            title = 'Balance Sheet';
            columns = const [];
            rows = const [];
            summary = r.summary;
          case 'trial-balance':
            final r = await _service.trialBalanceReport(
                auth.businessId, _asOfParam(q));
            title = 'Trial Balance';
            columns = r.table.columns;
            rows = r.table.rows;
            summary = r.totals;
          default:
            return ResponseEnvelope.badRequest(
                "Unknown financial report type '$type'");
        }
      default:
        return ResponseEnvelope.notFound("Unknown report '$report'");
    }

    try {
      final exported = await _exportService.export(
        format: format,
        reportType: reportType,
        title: title,
        columns: columns,
        rows: rows,
        summary: summary,
        businessId: auth.businessId,
        actorId: auth.userId,
      );
      return Response.ok(
        exported.bytes,
        headers: {
          'Content-Type': exported.mimeType,
          'Content-Disposition':
              'attachment; filename="${exported.fileName}"',
        },
      );
    } on ReportExportServiceException catch (e) {
      return ResponseEnvelope.badRequest(e.message);
    }
  }

  // -- Helpers ----------------------------------------------------------------

  String? _fromParam(Map<String, String> q) => q['from'] ?? q['from_date'];

  String? _toParam(Map<String, String> q) => q['to'] ?? q['to_date'];

  String? _asOfParam(Map<String, String> q) => q['as_of_date'] ?? q['asOfDate'];

  int? _intParam(Map<String, String> q, String snake, String camel) =>
      int.tryParse(q[snake] ?? q[camel] ?? '');
}
