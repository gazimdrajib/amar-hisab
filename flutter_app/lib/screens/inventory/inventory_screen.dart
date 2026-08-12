import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/stock.dart';
import '../../providers/app_providers.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/inventory_providers.dart';
import '../../widgets/common.dart';

/// Stock levels per warehouse with add / deduct / transfer / adjust actions.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warehouses = ref.watch(warehouseListProvider);
    final active = ref.watch(activeWarehouseProvider);
    final stock = active == null
        ? const AsyncLoading<List<StockEntry>>()
        : ref.watch(stockProvider(active.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          warehouses.when(
            data: (list) => list.isEmpty
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: DropdownButton<int>(
                      value: active?.id,
                      hint: const Text('Warehouse'),
                      underline: const SizedBox(),
                      items: list
                          .map((w) =>
                              DropdownMenuItem(value: w.id, child: Text(w.name)))
                          .toList(),
                      onChanged: (id) => id == null
                          ? null
                          : ref
                              .read(appSettingsProvider.notifier)
                              .setDefaultWarehouse(id),
                    ),
                  ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Add / Adjust / Transfer stock',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: const AdjustStockSheet(),
              ),
            ),
          ),
        ],
      ),
      body: stock.when(
        data: (entries) {
          final products = ref.watch(productListProvider).value ?? [];
          final byId = {for (final p in products) p.id: p};
          if (entries.isEmpty) {
            return const EmptyView(
              icon: Icons.warehouse_outlined,
              title: 'No stock recorded',
              subtitle: 'Use the + button to add stock to this warehouse.',
            );
          }
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final entry = entries[i];
              final product = byId[entry.productId];
              final low =
                  product != null && entry.quantity <= product.minStockLevel;
              return ListTile(
                leading: Icon(
                  low ? Icons.warning_amber : Icons.inventory_2_outlined,
                  color: low ? Colors.orange : null,
                ),
                title: Text(product?.name ?? 'Product #${entry.productId}'),
                subtitle: Text(product?.sku ?? ''),
                trailing: Text(
                  Fmt.qty(entry.quantity),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: low ? Colors.orange.shade800 : null,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
            error: e,
            onRetry: active == null
                ? null
                : () => ref.invalidate(stockProvider(active.id))),
      ),
    );
  }
}

enum _Action { add, deduct, adjust, transfer }

extension on _Action {
  String get label => switch (this) {
        _Action.add => 'Add stock',
        _Action.deduct => 'Deduct / Damaged',
        _Action.adjust => 'Correct quantity',
        _Action.transfer => 'Transfer between warehouses',
      };

  IconData get icon => switch (this) {
        _Action.add => Icons.add_circle_outline,
        _Action.deduct => Icons.remove_circle_outline,
        _Action.adjust => Icons.tune,
        _Action.transfer => Icons.swap_horiz,
      };
}

/// Bottom sheet for the four inventory mutations.
class AdjustStockSheet extends ConsumerStatefulWidget {
  const AdjustStockSheet({super.key});

  @override
  ConsumerState<AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends ConsumerState<AdjustStockSheet> {
  _Action _action = _Action.add;
  int? _productId;
  int? _toWarehouseId;
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final warehouse = ref.read(activeWarehouseProvider);
    final qty = double.tryParse(_qtyCtrl.text);
    if (warehouse == null) {
      showSnack(context, 'No warehouse selected', isError: true);
      return;
    }
    if (_productId == null) {
      showSnack(context, 'Select a product', isError: true);
      return;
    }
    if (qty == null || qty < 0) {
      showSnack(context, 'Enter a valid quantity', isError: true);
      return;
    }
    if (_action == _Action.transfer && _toWarehouseId == null) {
      showSnack(context, 'Select the destination warehouse', isError: true);
      return;
    }
    setState(() => _saving = true);
    final actions = ref.read(inventoryActionsProvider);
    try {
      switch (_action) {
        case _Action.add:
          await actions.addStock(
              productId: _productId!,
              warehouseId: warehouse.id,
              quantity: qty,
              note: _noteCtrl.text);
        case _Action.deduct:
          await actions.deductStock(
              productId: _productId!,
              warehouseId: warehouse.id,
              quantity: qty,
              note: _noteCtrl.text);
        case _Action.adjust:
          await actions.adjustStock(
              productId: _productId!,
              warehouseId: warehouse.id,
              newQuantity: qty,
              note: _noteCtrl.text);
        case _Action.transfer:
          await actions.transfer(
              productId: _productId!,
              fromWarehouseId: warehouse.id,
              toWarehouseId: _toWarehouseId!,
              quantity: qty,
              note: _noteCtrl.text);
      }
      ref.invalidate(stockProvider(warehouse.id));
      if (mounted) {
        showSnack(context, '${_action.label} saved');
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider).value ?? [];
    final warehouses = ref.watch(warehouseListProvider).value ?? [];
    final active = ref.watch(activeWarehouseProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock Operation',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _Action.values
                  .map((a) => ChoiceChip(
                        avatar: Icon(a.icon, size: 16),
                        label: Text(a.label),
                        selected: _action == a,
                        onSelected: (_) => setState(() => _action = a),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _productId,
              decoration: const InputDecoration(
                  labelText: 'Product', border: OutlineInputBorder()),
              items: products
                  .map((p) =>
                      DropdownMenuItem(value: p.id, child: Text(p.name)))
                  .toList(),
              onChanged: (v) => setState(() => _productId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              decoration: InputDecoration(
                labelText: _action == _Action.adjust
                    ? 'New total quantity'
                    : 'Quantity',
                border: const OutlineInputBorder(),
              ),
            ),
            if (_action == _Action.transfer) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _toWarehouseId,
                decoration: InputDecoration(
                  labelText: 'Transfer to (from ${active?.name ?? 'selected warehouse'})',
                  border: const OutlineInputBorder(),
                ),
                items: warehouses
                    .where((w) => w.id != active?.id)
                    .map((w) =>
                        DropdownMenuItem(value: w.id, child: Text(w.name)))
                    .toList(),
                onChanged: (v) => setState(() => _toWarehouseId = v),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'Note (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
