import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/inventory_providers.dart';
import '../../widgets/common.dart';
import 'checkout_sheet.dart';

/// POS search query typed into the left pane.
final posSearchProvider = StateProvider<String>((ref) => '');

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchCtrl = TextEditingController();
  final _scanCtrl = TextEditingController();
  final _scanFocus = FocusNode();
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scanCtrl.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  /// Barcode guns typically enter the code and press Enter — we hook that here.
  Future<void> _onScanSubmit(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return;
    final cart = ref.read(cartProvider.notifier);
    final cached = await ref.read(barcodeLookupProvider(code).future);
    if (!mounted) return;
    if (cached != null) {
      cart.addItem(cached);
      showSnack(context, '${cached.name} added');
    } else {
      showSnack(context, 'No product with barcode "$code"', isError: true);
    }
    _scanCtrl.clear();
    _scanFocus.requestFocus();
  }

  Future<void> _addByProduct(Product product) async {
    ref.read(cartProvider.notifier).addItem(product);
  }

  Future<void> _checkout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      showSnack(context, 'Cart is empty', isError: true);
      return;
    }
    final warehouse = ref.read(activeWarehouseProvider);
    if (warehouse == null) {
      showSnack(context, 'No warehouse configured', isError: true);
      return;
    }
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CheckoutSheet(warehouseId: warehouse.id),
      ),
    );
    if (result == true && mounted) {
      ref.read(cartProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(posSearchProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(Icons.warehouse, size: 16),
              label: Consumer(builder: (context, ref, _) {
                final warehouse = ref.watch(activeWarehouseProvider);
                return Text(warehouse?.name ?? 'No warehouse');
              }),
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------- Left: search + product grid -------------
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search products by name / SKU…',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: search.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      ref.read(posSearchProvider.notifier).state =
                                          '';
                                    },
                                  ),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) => ref
                              .read(posSearchProvider.notifier)
                              .state = value,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _scanCtrl,
                          focusNode: _scanFocus,
                          decoration: const InputDecoration(
                            hintText: 'Scan barcode & Enter',
                            prefixIcon: Icon(Icons.qr_code_scanner),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: _onScanSubmit,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: search.isEmpty
                      ? _AllProductsGrid(onTap: _addByProduct)
                      : _SearchResults(
                          query: search,
                          searching: _searching,
                          onSearchingChanged: (v) =>
                              setState(() => _searching = v),
                          onTap: _addByProduct,
                        ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // ------------- Right: cart -------------
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text('Cart (${cart.itemCount})',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Clear cart',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: cart.isEmpty
                              ? null
                              : () => ref.read(cartProvider.notifier).clear(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: cart.isEmpty
                        ? const EmptyView(
                            icon: Icons.shopping_cart_outlined,
                            title: 'Cart is empty',
                            subtitle: 'Search or scan to add items',
                          )
                        : ListView.separated(
                            itemCount: cart.items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = cart.items[i];
                              return ListTile(
                                dense: true,
                                title: Text(item.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                    '${Fmt.qty(item.quantity)} × ${Fmt.money(item.unitPrice)}'
                                    '${item.taxPercent > 0 ? ' · VAT ${item.taxPercent}%' : ''}'),
                                trailing: SizedBox(
                                  width: 170,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                                        onPressed: () => ref
                                            .read(cartProvider.notifier)
                                            .updateQuantity(item.productId,
                                                item.quantity - 1),
                                      ),
                                      Text(Fmt.qty(item.quantity),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        onPressed: () => ref
                                            .read(cartProvider.notifier)
                                            .updateQuantity(item.productId,
                                                item.quantity + 1),
                                      ),
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          Fmt.money(item.lineTotal),
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 1),
                  _Totals(cart: cart),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: cart.isEmpty ? null : _checkout,
                        icon: const Icon(Icons.payment),
                        label: Text(
                            'Charge ${Fmt.money(cart.grandTotal)}'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  final CartState cart;
  const _Totals({required this.cart});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _row('Subtotal', Fmt.money(cart.subtotal), style),
          if (cart.discountAmount > 0)
            _row('Discount', '- ${Fmt.money(cart.discountAmount)}', style),
          if (cart.taxAmount > 0) _row('VAT', Fmt.money(cart.taxAmount), style),
          const SizedBox(height: 4),
          _row(
            'Total',
            Fmt.money(cart.grandTotal),
            Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, TextStyle? style) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label, style: style), Text(value, style: style)],
        ),
      );
}

class _AllProductsGrid extends ConsumerWidget {
  final void Function(Product) onTap;
  const _AllProductsGrid({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider);
    return products.when(
      data: (list) => GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 190,
          mainAxisExtent: 120,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: list.length,
        itemBuilder: (context, i) =>
            _ProductCard(product: list[i], onTap: onTap),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.read(productListProvider.notifier).refresh()),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;
  final bool searching;
  final ValueChanged<bool> onSearchingChanged;
  final void Function(Product) onTap;

  const _SearchResults({
    required this.query,
    required this.searching,
    required this.onSearchingChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider).value ?? [];
    final q = query.toLowerCase();
    final matches = products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            (p.barcode?.toLowerCase().contains(q) ?? false))
        .toList();
    if (matches.isEmpty) {
      return const EmptyView(
          icon: Icons.search_off, title: 'No matching products');
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisExtent: 120,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: matches.length,
      itemBuilder: (context, i) =>
          _ProductCard(product: matches[i], onTap: onTap),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final void Function(Product) onTap;
  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(product),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(product.sku,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis),
              const Spacer(),
              Text(Fmt.money(product.sellingPrice),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
