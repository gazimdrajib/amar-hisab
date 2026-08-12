import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/purchases_providers.dart';
import '../../providers/sales_providers.dart';
import '../../widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(dueSalesProvider);
    ref.invalidate(duePurchasesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final dueSales = ref.watch(dueSalesProvider);
    final duePurchases = ref.watch(duePurchasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            summary.when(
              data: (s) => _KpiGrid(summary: s),
              loading: () => const SizedBox(
                  height: 180, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => ErrorView(error: e, onRetry: () => _refresh(ref)),
            ),
            const SizedBox(height: 24),
            Text('Low Stock Alerts',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            summary.maybeWhen(
              data: (s) => s.lowStockCount > 0
                  ? _LowStockWarning(count: s.lowStockCount)
                  : const _OkCard(
                      text: 'All products are above minimum stock level.',
                      icon: Icons.check_circle_outline,
                    ),
              orElse: () => const SizedBox(
                  height: 40, child: Center(child: CircularProgressIndicator())),
            ),
            const SizedBox(height: 24),
            Text('Due Reminders — Sales (Receivable)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            dueSales.when(
              data: (sales) => sales.isEmpty
                  ? const _OkCard(
                      text: 'No outstanding customer dues.',
                      icon: Icons.thumb_up_outlined,
                    )
                  : Column(
                      children: sales.take(5).map((sale) => Card(
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.receipt_outlined),
                              title: Text(sale.invoiceNumber),
                              subtitle: Text(Fmt.date(sale.saleDate)),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(Fmt.money(sale.dueAmount),
                                      style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.bold)),
                                  StatusChip(sale.paymentStatus),
                                ],
                              ),
                            ),
                          )).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const _OfflineNote(),
            ),
            const SizedBox(height: 24),
            Text('Due Reminders — Suppliers (Payable)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            duePurchases.when(
              data: (purchases) => purchases.isEmpty
                  ? const _OkCard(
                      text: 'No outstanding supplier dues.',
                      icon: Icons.thumb_up_outlined,
                    )
                  : Column(
                      children: purchases.take(5).map((purchase) => Card(
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.shopping_cart_checkout),
                              title: Text(purchase.invoiceNumber),
                              subtitle: Text(Fmt.date(purchase.purchaseDate)),
                              trailing: Text(Fmt.money(purchase.dueAmount),
                                  style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold)),
                            ),
                          )).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const _OfflineNote(),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final DashboardSummary summary;
  const _KpiGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.today, "Today's Sales", summary.todaySales, Colors.green),
      (Icons.receipt, 'Invoices Today',
          summary.invoiceCount.toDouble(), Colors.blue),
      (Icons.calendar_month, 'This Month', summary.monthSales, Colors.indigo),
      (Icons.payments_outlined, 'Collected Today', summary.todayPaid,
          Colors.teal),
      (Icons.money_off, 'Due Today', summary.todayDue, Colors.orange),
      (Icons.inventory, 'Stock Value', summary.totalStockValue, Colors.brown),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisExtent: 110,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        final isCount = item.$2 == 'Invoices Today';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(item.$1, size: 18, color: item.$4),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item.$2,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const Spacer(),
                Text(
                  isCount
                      ? item.$3.toInt().toString()
                      : Fmt.compactMoney(item.$3),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: item.$4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LowStockWarning extends StatelessWidget {
  final int count;
  const _LowStockWarning({required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: ListTile(
        leading: Icon(Icons.warning_amber, color: Colors.red.shade700),
        title: Text('$count product${count > 1 ? 's' : ''} below minimum stock',
            style: TextStyle(color: Colors.red.shade900)),
        subtitle:
            const Text('Review Inventory → stock levels and restock soon.'),
      ),
    );
  }
}

class _OkCard extends StatelessWidget {
  final String text;
  final IconData icon;
  const _OkCard({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: ListTile(
        leading: Icon(icon, color: Colors.green.shade700),
        title: Text(text, style: TextStyle(color: Colors.green.shade900)),
      ),
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        dense: true,
        leading: Icon(Icons.cloud_off),
        title: Text('Could not load due reminders (check connection).'),
      ),
    );
  }
}
