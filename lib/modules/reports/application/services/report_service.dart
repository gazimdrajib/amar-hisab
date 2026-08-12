import 'package:sqlite3/sqlite3.dart';

import '../../../../core/services/audit_service.dart';
import '../../../accounting/application/services/ledger_service.dart';
import '../../domain/entities/report_results.dart';
import '../../domain/entities/report_table.dart';

/// Error raised by [ReportService]; carries a machine-readable [code] the
/// controller maps to an HTTP status.
class ReportServiceException implements Exception {
  const ReportServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ReportServiceException($code): $message';
}

/// Pre-computed report projections (Architecture Book §14.7 – Reports module).
///
/// [ReportService] is read-only: it produces the six documented reports by
/// querying the transactional tables scoped to `business_id`:
///
///  * [salesReport]      – one row per sale in a date range.
///  * [purchaseReport]   – one row per purchase in a date range.
///  * [inventoryReport]  – current stock per product/warehouse with valuation.
///  * [profitLossReport] / [balanceSheetReport] / [trialBalanceReport] –
///    delegated to [LedgerService] so financial statements are guaranteed to
///    be consistent with the double-entry ledger.
class ReportService {
  ReportService(this._db, this._ledgerService, this._audit);

  final Database _db;
  final LedgerService _ledgerService;
  final AuditService _audit;

  double _round2(Object? v) =>
      (((v as num?)?.toDouble() ?? 0) * 100).roundToDouble() / 100;

  // -- Sales report ---------------------------------------------------------

  /// One row per (non-cancelled) sale between [from] and [to], optionally
  /// filtered by [customerId]; the `product_id` restriction matches sales
  /// that contain the given product in any line item.
  Future<SalesReportResult> salesReport(
    int businessId, {
    String? from,
    String? to,
    int? customerId,
    int? productId,
  }) async {
    final where = StringBuffer(
        "s.business_id = ? AND s.status != 'Cancelled'");
    final args = <Object?>[businessId];
    if (from != null) {
      where.write(' AND s.sale_date >= ?');
      args.add(from);
    }
    if (to != null) {
      where.write(' AND s.sale_date <= ?');
      args.add(to);
    }
    if (customerId != null) {
      where.write(' AND s.customer_id = ?');
      args.add(customerId);
    }
    if (productId != null) {
      where.write(
          ' AND EXISTS (SELECT 1 FROM sale_items si '
          'WHERE si.sale_id = s.id AND si.product_id = ?)');
      args.add(productId);
    }

    final rows = _db.select('''
      SELECT
        s.sale_date,
        s.invoice_number,
        COALESCE(c.name, '') AS customer_name,
        s.sale_type,
        s.payment_status,
        s.total_amount,
        s.discount_amount,
        s.tax_amount,
        s.grand_total,
        s.paid_amount,
        s.due_amount,
        s.status
      FROM sales s
      LEFT JOIN customers c ON c.id = s.customer_id
      WHERE $where
      ORDER BY s.sale_date, s.id;
    ''', args);

    final table = ReportTable(
      columns: const [
        ReportColumn('date', 'Date'),
        ReportColumn('invoice_number', 'Invoice #'),
        ReportColumn('customer', 'Customer'),
        ReportColumn('sale_type', 'Type'),
        ReportColumn('payment_status', 'Payment'),
        ReportColumn('total', 'Total', isNumeric: true),
        ReportColumn('discount', 'Discount', isNumeric: true),
        ReportColumn('tax', 'Tax', isNumeric: true),
        ReportColumn('grand_total', 'Grand Total', isNumeric: true),
        ReportColumn('paid', 'Paid', isNumeric: true),
        ReportColumn('due', 'Due', isNumeric: true),
        ReportColumn('status', 'Status'),
      ],
      rows: [
        for (final r in rows)
          {
            'date': r['sale_date'],
            'invoice_number': r['invoice_number'],
            'customer': r['customer_name'],
            'sale_type': r['sale_type'],
            'payment_status': r['payment_status'],
            'total': _round2(r['total_amount']),
            'discount': _round2(r['discount_amount']),
            'tax': _round2(r['tax_amount']),
            'grand_total': _round2(r['grand_total']),
            'paid': _round2(r['paid_amount']),
            'due': _round2(r['due_amount']),
            'status': r['status'],
          },
      ],
    );

    final totals = _db.select('''
      SELECT
        COUNT(*) AS invoice_count,
        COALESCE(SUM(s.grand_total), 0) AS total_sales,
        COALESCE(SUM(s.discount_amount), 0) AS total_discount,
        COALESCE(SUM(s.tax_amount), 0) AS total_tax,
        COALESCE(SUM(s.paid_amount), 0) AS total_paid,
        COALESCE(SUM(s.due_amount), 0) AS total_due
      FROM sales s
      WHERE $where;
    ''', args);

    final t = totals.first;
    _audit.logAction(
      entityType: 'report',
      entityId: 0,
      action: 'generate:sales',
      newValue:
          'from=$from; to=$to; customer=$customerId; product=$productId',
      businessId: businessId,
    );
    return SalesReportResult(
      filters: ReportFilters(
          from: from, to: to, customerId: customerId, productId: productId),
      table: table,
      summary: [
        SummaryItem('invoice_count', 'Invoices', t['invoice_count'],
            isNumeric: false),
        SummaryItem('total_sales', 'Total Sales', _round2(t['total_sales'])),
        SummaryItem(
            'total_discount', 'Total Discount', _round2(t['total_discount'])),
        SummaryItem('total_tax', 'Total Tax', _round2(t['total_tax'])),
        SummaryItem('total_paid', 'Total Paid', _round2(t['total_paid'])),
        SummaryItem('total_due', 'Total Due', _round2(t['total_due'])),
      ],
    );
  }

  // -- Purchase report ------------------------------------------------------

  /// One row per purchase invoice between [from] and [to], optionally
  /// filtered by [supplierId]; the `product_id` restriction matches purchases
  /// that contain the given product in any line item.
  Future<PurchaseReportResult> purchaseReport(
    int businessId, {
    String? from,
    String? to,
    int? supplierId,
    int? productId,
  }) async {
    final where = StringBuffer('p.business_id = ?');
    final args = <Object?>[businessId];
    if (from != null) {
      where.write(' AND p.purchase_date >= ?');
      args.add(from);
    }
    if (to != null) {
      where.write(' AND p.purchase_date <= ?');
      args.add(to);
    }
    if (supplierId != null) {
      where.write(' AND p.supplier_id = ?');
      args.add(supplierId);
    }
    if (productId != null) {
      where.write(
          ' AND EXISTS (SELECT 1 FROM purchase_items pi '
          'WHERE pi.purchase_id = p.id AND pi.product_id = ?)');
      args.add(productId);
    }

    final rows = _db.select('''
      SELECT
        p.purchase_date,
        p.invoice_number,
        COALESCE(s.name, '') AS supplier_name,
        p.payment_status,
        p.total_amount,
        p.discount_amount,
        p.tax_amount,
        p.grand_total,
        p.paid_amount,
        p.due_amount,
        p.status
      FROM purchases p
      LEFT JOIN suppliers s ON s.id = p.supplier_id
      WHERE $where
      ORDER BY p.purchase_date, p.id;
    ''', args);

    final table = ReportTable(
      columns: const [
        ReportColumn('date', 'Date'),
        ReportColumn('invoice_number', 'Invoice #'),
        ReportColumn('supplier', 'Supplier'),
        ReportColumn('payment_status', 'Payment'),
        ReportColumn('total', 'Total', isNumeric: true),
        ReportColumn('discount', 'Discount', isNumeric: true),
        ReportColumn('tax', 'Tax', isNumeric: true),
        ReportColumn('grand_total', 'Grand Total', isNumeric: true),
        ReportColumn('paid', 'Paid', isNumeric: true),
        ReportColumn('due', 'Due', isNumeric: true),
        ReportColumn('status', 'Status'),
      ],
      rows: [
        for (final r in rows)
          {
            'date': r['purchase_date'],
            'invoice_number': r['invoice_number'],
            'supplier': r['supplier_name'],
            'payment_status': r['payment_status'],
            'total': _round2(r['total_amount']),
            'discount': _round2(r['discount_amount']),
            'tax': _round2(r['tax_amount']),
            'grand_total': _round2(r['grand_total']),
            'paid': _round2(r['paid_amount']),
            'due': _round2(r['due_amount']),
            'status': r['status'],
          },
      ],
    );

    final totals = _db.select('''
      SELECT
        COUNT(*) AS invoice_count,
        COALESCE(SUM(p.grand_total), 0) AS total_purchases,
        COALESCE(SUM(p.tax_amount), 0) AS total_tax,
        COALESCE(SUM(p.paid_amount), 0) AS total_paid,
        COALESCE(SUM(p.due_amount), 0) AS total_due
      FROM purchases p
      WHERE $where;
    ''', args);

    final t = totals.first;
    _audit.logAction(
      entityType: 'report',
      entityId: 0,
      action: 'generate:purchases',
      newValue:
          'from=$from; to=$to; supplier=$supplierId; product=$productId',
      businessId: businessId,
    );
    return PurchaseReportResult(
      filters: ReportFilters(
          from: from, to: to, supplierId: supplierId, productId: productId),
      table: table,
      summary: [
        SummaryItem('invoice_count', 'Invoices', t['invoice_count'],
            isNumeric: false),
        SummaryItem(
            'total_purchases', 'Total Purchases', _round2(t['total_purchases'])),
        SummaryItem('total_tax', 'Total Tax', _round2(t['total_tax'])),
        SummaryItem('total_paid', 'Total Paid', _round2(t['total_paid'])),
        SummaryItem('total_due', 'Total Due', _round2(t['total_due'])),
      ],
    );
  }

  // -- Inventory report -----------------------------------------------------

  /// Current stock per product/warehouse, valued at the product purchase
  /// price. Optionally restricted to one [warehouseId] / [productId].
  Future<InventoryReportResult> inventoryReport(
    int businessId, {
    int? warehouseId,
    int? productId,
  }) async {
    final where =
        StringBuffer('st.business_id = ? AND p.is_active = 1');
    final args = <Object?>[businessId];
    if (warehouseId != null) {
      where.write(' AND st.warehouse_id = ?');
      args.add(warehouseId);
    }
    if (productId != null) {
      where.write(' AND st.product_id = ?');
      args.add(productId);
    }

    final rows = _db.select('''
      SELECT
        p.sku,
        p.name AS product_name,
        w.name AS warehouse_name,
        st.quantity,
        p.selling_price,
        p.purchase_price,
        COALESCE(st.quantity, 0) * p.purchase_price AS stock_value,
        CASE WHEN st.quantity <= p.min_stock_level THEN 1 ELSE 0 END
          AS is_low_stock
      FROM stock st
      JOIN products p   ON p.id = st.product_id
      JOIN warehouses w ON w.id = st.warehouse_id
      WHERE $where
      ORDER BY p.name, w.name;
    ''', args);

    final table = ReportTable(
      columns: const [
        ReportColumn('sku', 'SKU'),
        ReportColumn('product', 'Product'),
        ReportColumn('warehouse', 'Warehouse'),
        ReportColumn('quantity', 'Quantity', isNumeric: true),
        ReportColumn('selling_price', 'Sell Price', isNumeric: true),
        ReportColumn('purchase_price', 'Cost Price', isNumeric: true),
        ReportColumn('stock_value', 'Stock Value', isNumeric: true),
        ReportColumn('low_stock', 'Low Stock'),
      ],
      rows: [
        for (final r in rows)
          {
            'sku': r['sku'],
            'product': r['product_name'],
            'warehouse': r['warehouse_name'],
            'quantity': _round2(r['quantity']),
            'selling_price': _round2(r['selling_price']),
            'purchase_price': _round2(r['purchase_price']),
            'stock_value': _round2(r['stock_value']),
            'low_stock': (r['is_low_stock'] as num?) == 1 ? 'Yes' : 'No',
          },
      ],
    );

    final totals = _db.select('''
      SELECT
        COUNT(*) AS line_count,
        COALESCE(SUM(st.quantity), 0) AS total_quantity,
        COALESCE(SUM(st.quantity * p.purchase_price), 0) AS total_value,
        COALESCE(SUM(CASE WHEN st.quantity <= p.min_stock_level
                          THEN 1 ELSE 0 END), 0) AS low_stock_count
      FROM stock st
      JOIN products p ON p.id = st.product_id
      WHERE $where;
    ''', args);

    final t = totals.first;
    _audit.logAction(
      entityType: 'report',
      entityId: 0,
      action: 'generate:inventory',
      newValue: 'warehouse=$warehouseId; product=$productId',
      businessId: businessId,
    );
    return InventoryReportResult(
      filters: ReportFilters(warehouseId: warehouseId, productId: productId),
      table: table,
      summary: [
        SummaryItem('line_count', 'Stock Lines', t['line_count'],
            isNumeric: false),
        SummaryItem(
            'total_quantity', 'Total Quantity', _round2(t['total_quantity'])),
        SummaryItem('total_value', 'Total Value', _round2(t['total_value'])),
        SummaryItem(
            'low_stock_count', 'Low Stock Items', t['low_stock_count'],
            isNumeric: false),
      ],
    );
  }

  // -- Financial reports (delegated to LedgerService so statements are      --
  //    consistent with the double-entry ledger, Architecture Book §14.2)    --

  /// Profit & Loss for [from] – [to]. Parameters are positional, matching the
  /// documented `profitLossReport(from, to)` signature.
  Future<ProfitLossReportResult> profitLossReport(
    int businessId,
    String? from,
    String? to,
  ) async {
    final result = await _ledgerService.getProfitLoss(
      businessId,
      fromDate: from,
      toDate: to,
    );
    _audit.logAction(
      entityType: 'report',
      entityId: 0,
      action: 'generate:profit_loss',
      newValue: 'from=$from; to=$to',
      businessId: businessId,
    );
    return ProfitLossReportResult(
      filters: ReportFilters(from: from, to: to),
      revenue: (result['revenue'] as num?)?.toDouble() ?? 0,
      expenses: (result['expenses'] as num?)?.toDouble() ?? 0,
      netProfit: (result['net_profit'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Balance sheet as of [asOfDate]. Parameter is positional, matching the
  /// documented `balanceSheetReport(asOfDate)` signature.
  Future<BalanceSheetReportResult> balanceSheetReport(
    int businessId,
    String? asOfDate,
  ) async {
    final result = await _ledgerService.getBalanceSheet(
      businessId,
      asOfDate: asOfDate,
    );
    _audit.logAction(
      entityType: 'report',
      entityId: 0,
      action: 'generate:balance_sheet',
      newValue: 'as_of_date=$asOfDate',
      businessId: businessId,
    );
    return BalanceSheetReportResult(
      filters: ReportFilters(asOfDate: asOfDate),
      assets: (result['assets'] as num?)?.toDouble() ?? 0,
      liabilities: (result['liabilities'] as num?)?.toDouble() ?? 0,
      equity: (result['equity'] as num?)?.toDouble() ?? 0,
      netWorth: (result['net_worth'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Trial balance as of [asOfDate]. Parameter is positional, matching the
  /// documented `trialBalanceReport(asOfDate)` signature.
  Future<TrialBalanceReportResult> trialBalanceReport(
    int businessId,
    String? asOfDate,
  ) async {
    final rows = await _ledgerService.getTrialBalance(
      businessId,
      asOfDate: asOfDate,
    );

    var totalDebit = 0.0;
    var totalCredit = 0.0;
    final tableRows = <Map<String, dynamic>>[];
    for (final r in rows) {
      final debit = _round2(r['debit']);
      final credit = _round2(r['credit']);
      totalDebit += debit;
      totalCredit += credit;
      tableRows.add({
        'account_code': r['account_code'],
        'account_name': r['account_name'],
        'account_type': r['account_type'],
        'debit': debit,
        'credit': credit,
      });
    }

    _audit.logAction(
      entityType: 'report',
      entityId: 0,
      action: 'generate:trial_balance',
      newValue: 'as_of_date=$asOfDate',
      businessId: businessId,
    );
    return TrialBalanceReportResult(
      filters: ReportFilters(asOfDate: asOfDate),
      table: ReportTable(
        columns: const [
          ReportColumn('account_code', 'Code'),
          ReportColumn('account_name', 'Account'),
          ReportColumn('account_type', 'Type'),
          ReportColumn('debit', 'Debit', isNumeric: true),
          ReportColumn('credit', 'Credit', isNumeric: true),
        ],
        rows: tableRows,
      ),
      totals: [
        SummaryItem('total_debit', 'Total Debit', _round2(totalDebit)),
        SummaryItem('total_credit', 'Total Credit', _round2(totalCredit)),
      ],
    );
  }
}
