import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/sale.dart';
import '../../providers/sales_providers.dart';
import '../../widgets/common.dart';

/// Sales history list — tap a row for full SaleDetail with items & payments.
class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  String? _paymentStatusFilter;

  @override
  Widget build(BuildContext context) {
    final sales = ref.watch(salesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButton<String?>(
              value: _paymentStatusFilter,
              hint: const Text('Filter'),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                DropdownMenuItem(value: 'Due', child: Text('Due')),
              ],
              onChanged: (v) => setState(() => _paymentStatusFilter = v),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(salesListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: sales.when(
        data: (list) {
          final filtered = _paymentStatusFilter == null
              ? list
              : list
                  .where((s) => s.paymentStatus == _paymentStatusFilter)
                  .toList();
          if (filtered.isEmpty) {
            return const EmptyView(
                icon: Icons.receipt_long, title: 'No sales recorded yet');
          }
          return ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final sale = filtered[i];
              return ListTile(
                leading: const Icon(Icons.receipt_outlined),
                title: Text(sale.invoiceNumber),
                subtitle: Text(
                    '${Fmt.dateTime(sale.saleDate)}  ·  ${sale.saleType}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(Fmt.money(sale.grandTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    StatusChip(sale.paymentStatus),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => SaleDetailScreen(saleId: sale.id)),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.read(salesListProvider.notifier).refresh()),
      ),
    );
  }
}

class SaleDetailScreen extends ConsumerWidget {
  final int saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(saleDetailProvider(saleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Sale Detail')),
      body: detail.when(
        data: (sale) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(sale: sale),
            const SizedBox(height: 16),
            Text('Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: sale.items
                    .map((item) => ListTile(
                          dense: true,
                          title: Text('Product #${item.productId}'),
                          subtitle: Text(
                              '${Fmt.qty(item.quantity)} × ${Fmt.money(item.unitPrice)}'
                              '${item.discountPercent > 0 ? ' · -${item.discountPercent}%' : ''}'
                              '${item.taxPercent > 0 ? ' · VAT ${item.taxPercent}%' : ''}'),
                          trailing: Text(Fmt.money(item.lineTotal),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Payments', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: sale.payments.isEmpty
                  ? const ListTile(
                      dense: true, title: Text('No payment recorded (Due).'))
                  : Column(
                      children: sale.payments
                          .map((p) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.payments_outlined),
                                title: Text(p.paymentMethod),
                                subtitle: Text(Fmt.dateTime(p.paymentDate)),
                                trailing: Text(Fmt.money(p.amount)),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _row('Subtotal', Fmt.money(sale.totalAmount)),
                  if (sale.discountAmount > 0)
                    _row('Discount', '- ${Fmt.money(sale.discountAmount)}'),
                  if (sale.taxAmount > 0)
                    _row('VAT', Fmt.money(sale.taxAmount)),
                  const Divider(),
                  _row('Grand Total', Fmt.money(sale.grandTotal), bold: true),
                  _row('Paid', Fmt.money(sale.paidAmount)),
                  _row('Due', Fmt.money(sale.dueAmount),
                      color: sale.dueAmount > 0 ? Colors.orange : Colors.green),
                ]),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    color: color)),
          ],
        ),
      );
}

class _Header extends StatelessWidget {
  final Sale sale;
  const _Header({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(sale.invoiceNumber,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                StatusChip(sale.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(Fmt.dateTime(sale.saleDate)),
            Text('Type: ${sale.saleType}'),
            if (sale.note != null && sale.note!.isNotEmpty)
              Text('Note: ${sale.note}'),
          ],
        ),
      ),
    );
  }
}
