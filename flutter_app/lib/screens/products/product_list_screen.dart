import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/common.dart';
import 'product_form_screen.dart';

/// Management list of all products with search + CRUD.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(productListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Product'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductFormScreen()),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Filter by name / SKU / barcode…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: products.when(
              data: (list) {
                final filtered = _query.isEmpty
                    ? list
                    : list
                        .where((p) =>
                            p.name.toLowerCase().contains(_query) ||
                            p.sku.toLowerCase().contains(_query) ||
                            (p.barcode?.toLowerCase().contains(_query) ?? false))
                        .toList();
                if (filtered.isEmpty) {
                  return const EmptyView(
                      icon: Icons.inventory_2_outlined,
                      title: 'No products found');
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      _ProductRow(product: filtered[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () =>
                      ref.read(productListProvider.notifier).refresh()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends ConsumerWidget {
  final Product product;
  const _ProductRow({required this.product});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate product?'),
        content: Text(
            '"${product.name}" will be deactivated but kept for history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deactivate')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(productListProvider.notifier).delete(product.id);
      if (context.mounted) showSnack(context, 'Product deactivated');
    } on ApiException catch (e) {
      if (context.mounted) showSnack(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(child: Text(product.name.characters.first)),
      title: Text(product.name,
          style: TextStyle(
              decoration: product.isActive ? null : TextDecoration.lineThrough)),
      subtitle: Text('SKU ${product.sku}'
          '${product.barcode != null ? ' · ${product.barcode}' : ''}'
          ' · Buy ${Fmt.money(product.purchasePrice)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(Fmt.money(product.sellingPrice),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => ProductFormScreen(product: product)),
            ),
          ),
          IconButton(
            tooltip: 'Deactivate',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
    );
  }
}
