import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/network/api_client.dart';
import '../models/report.dart';
import 'app_providers.dart';

class DashboardSummary {
  final double todaySales;
  final double todayPaid;
  final double todayDue;
  final int invoiceCount;
  final double monthSales;
  final double monthDue;
  final int lowStockCount;
  final double totalStockValue;
  final double totalReceivable;
  final double totalPayable;
  final DateTime fetchedAt;

  const DashboardSummary({
    this.todaySales = 0,
    this.todayPaid = 0,
    this.todayDue = 0,
    this.invoiceCount = 0,
    this.monthSales = 0,
    this.monthDue = 0,
    this.lowStockCount = 0,
    this.totalStockValue = 0,
    this.totalReceivable = 0,
    this.totalPayable = 0,
    required this.fetchedAt,
  });
}

/// Aggregates sales + inventory reports into dashboard KPIs.
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final api = ref.read(apiClientProvider);
  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);
  final monthStart = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month));

  Future<ReportTable?> safeReport(String name,
      [Map<String, dynamic>? query]) async {
    try {
      final data = await api.get(ApiEndpoints.report(name),
          query: query) as Map<String, dynamic>;
      return ReportTable.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  final todayReport =
      await safeReport('sales', {'from': today, 'to': today});
  final monthReport =
      await safeReport('sales', {'from': monthStart, 'to': today});
  final inventoryReport = await safeReport('inventory');
  final payableReport =
      await safeReport('purchases', {'from': monthStart, 'to': today});

  return DashboardSummary(
    todaySales: todayReport?.summaryNumber('total_sales') ?? 0,
    todayPaid: todayReport?.summaryNumber('total_paid') ?? 0,
    todayDue: todayReport?.summaryNumber('total_due') ?? 0,
    invoiceCount: todayReport?.summaryNumber('invoice_count').toInt() ?? 0,
    monthSales: monthReport?.summaryNumber('total_sales') ?? 0,
    monthDue: monthReport?.summaryNumber('total_due') ?? 0,
    lowStockCount: inventoryReport?.summaryNumber('low_stock_count').toInt() ?? 0,
    totalStockValue: inventoryReport?.summaryNumber('total_value') ?? 0,
    totalReceivable: monthReport?.summaryNumber('total_due') ?? 0,
    totalPayable: payableReport?.summaryNumber('total_due') ?? 0,
    fetchedAt: now,
  );
});
