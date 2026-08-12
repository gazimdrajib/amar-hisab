import 'report_table.dart';

/// Filter metadata echoed back to the caller so report consumers can render
/// the exact filter state that produced the result.
class ReportFilters {
  const ReportFilters({
    this.from,
    this.to,
    this.asOfDate,
    this.customerId,
    this.supplierId,
    this.productId,
    this.warehouseId,
  });

  final String? from;
  final String? to;
  final String? asOfDate;
  final int? customerId;
  final int? supplierId;
  final int? productId;
  final int? warehouseId;

  Map<String, dynamic> toJson() => {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (asOfDate != null) 'as_of_date': asOfDate,
        if (customerId != null) 'customer_id': customerId,
        if (supplierId != null) 'supplier_id': supplierId,
        if (productId != null) 'product_id': productId,
        if (warehouseId != null) 'warehouse_id': warehouseId,
      };
}

/// Sales report: one row per sale, plus aggregate summary totals
/// (Architecture Book §14.7 – `ReportService` sales report).
class SalesReportResult {
  const SalesReportResult({
    required this.filters,
    required this.table,
    required this.summary,
  });

  final ReportFilters filters;
  final ReportTable table;
  final List<SummaryItem> summary;

  Map<String, dynamic> toJson() => {
        'filters': filters.toJson(),
        ...table.toJson(),
        'summary': summary.map((s) => s.toJson()).toList(),
      };
}

/// Purchase report: one row per purchase invoice, plus aggregate summary.
class PurchaseReportResult {
  const PurchaseReportResult({
    required this.filters,
    required this.table,
    required this.summary,
  });

  final ReportFilters filters;
  final ReportTable table;
  final List<SummaryItem> summary;

  Map<String, dynamic> toJson() => {
        'filters': filters.toJson(),
        ...table.toJson(),
        'summary': summary.map((s) => s.toJson()).toList(),
      };
}

/// Inventory report: current stock per product/warehouse, with valuation.
class InventoryReportResult {
  const InventoryReportResult({
    required this.filters,
    required this.table,
    required this.summary,
  });

  final ReportFilters filters;
  final ReportTable table;
  final List<SummaryItem> summary;

  Map<String, dynamic> toJson() => {
        'filters': filters.toJson(),
        ...table.toJson(),
        'summary': summary.map((s) => s.toJson()).toList(),
      };
}

/// Profit & Loss statement for a date range.
class ProfitLossReportResult {
  const ProfitLossReportResult({
    required this.filters,
    required this.revenue,
    required this.expenses,
    required this.netProfit,
  });

  final ReportFilters filters;
  final double revenue;
  final double expenses;
  final double netProfit;

  List<SummaryItem> get summary => [
        SummaryItem('revenue', 'Revenue', revenue),
        SummaryItem('expenses', 'Expenses', expenses),
        SummaryItem('net_profit', 'Net Profit', netProfit),
      ];

  Map<String, dynamic> toJson() => {
        'filters': filters.toJson(),
        'summary': summary.map((s) => s.toJson()).toList(),
      };
}

/// Balance sheet up to a given date.
class BalanceSheetReportResult {
  const BalanceSheetReportResult({
    required this.filters,
    required this.assets,
    required this.liabilities,
    required this.equity,
    required this.netWorth,
  });

  final ReportFilters filters;
  final double assets;
  final double liabilities;
  final double equity;
  final double netWorth;

  List<SummaryItem> get summary => [
        SummaryItem('assets', 'Assets', assets),
        SummaryItem('liabilities', 'Liabilities', liabilities),
        SummaryItem('equity', 'Equity', equity),
        SummaryItem('net_worth', 'Net Worth', netWorth),
      ];

  Map<String, dynamic> toJson() => {
        'filters': filters.toJson(),
        'summary': summary.map((s) => s.toJson()).toList(),
      };
}

/// Trial balance: debit/credit totals per account.
class TrialBalanceReportResult {
  const TrialBalanceReportResult({
    required this.filters,
    required this.table,
    required this.totals,
  });

  final ReportFilters filters;
  final ReportTable table;
  final List<SummaryItem> totals;

  Map<String, dynamic> toJson() => {
        'filters': filters.toJson(),
        ...table.toJson(),
        'summary': totals.map((s) => s.toJson()).toList(),
      };
}
