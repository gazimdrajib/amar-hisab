import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../providers/purchases_providers.dart';
import '../../widgets/common.dart';

/// Purchase history list with detail view.
class PurchaseHistoryScreen extends ConsumerWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchases = ref.watch(purchasesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(purchasesListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: purchases.when(
        data: (list) => list.isEmpty
            ? const EmptyView(
                icon: Icons.shopping_cart_outlined,
                title: 'No purchases recorded yet')
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final purchase = list[i];
                  return ListTile(
                    leading: const Icon(Icons.shopping_cart_checkout),
                    title: Text(purchase.invoiceNumber),
                    subtitle: Text(Fmt.dateTime(purchase.purchaseDate)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(Fmt.money(purchase.grandTotal),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        StatusChip(purchase.paymentStatus),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            PurchaseDetailScreen(purchaseId: purchase.id))),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.read(purchasesListProvider.notifier).refresh()),
      ),
    );
  }
}

class PurchaseDetailScreen extends ConsumerWidget {
  final int purchaseId;
  const PurchaseDetailScreen({super.key, required this.purchaseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(purchaseDetailProvider(purchaseId));
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Detail')),
      body: detail.when(
        data: (purchase) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(purchase.invoiceNumber,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        StatusChip(purchase.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(Fmt.dateTime(purchase.purchaseDate)),
                    if (purchase.note != null && purchase.note!.isNotEmpty)
                      Text('Note: ${purchase.note}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: purchase.items
                    .map((item) => ListTile(
                          dense: true,
                          title: Text('Product #${item.productId}'),
                          subtitle: Text(
                              '${Fmt.qty(item.quantity)} × ${Fmt.money(item.unitPrice)}'),
                          trailing: Text(Fmt.money(item.lineTotal),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _row(context, 'Total', Fmt.money(purchase.totalAmount)),
                  if (purchase.discountAmount > 0)
                    _row(context, 'Discount',
                        '- ${Fmt.money(purchase.discountAmount)}'),
                  if (purchase.taxAmount > 0)
                    _row(context, 'VAT', Fmt.money(purchase.taxAmount)),
                  const Divider(),
                  _row(context, 'Grand Total', Fmt.money(purchase.grandTotal),
                      bold: true),
                  _row(context, 'Paid', Fmt.money(purchase.paidAmount)),
                  _row(context, 'Due', Fmt.money(purchase.dueAmount),
                      color: purchase.dueAmount > 0 ? Colors.orange : null),
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

  Widget _row(BuildContext context, String label, String value,
          {bool bold = false, Color? color}) =>
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
