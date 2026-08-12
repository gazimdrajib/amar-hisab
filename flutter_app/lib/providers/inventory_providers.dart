import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/storage/local_db.dart';
import '../models/stock.dart';
import 'app_providers.dart';

class WarehouseListNotifier extends AsyncNotifier<List<Warehouse>> {
  @override
  Future<List<Warehouse>> build() async {
    try {
      final data =
          await ref.read(apiClientProvider).get(ApiEndpoints.warehouses) as List;
      final warehouses =
          data.map((e) => Warehouse.fromJson(e as Map<String, dynamic>)).toList();
      await LocalDb.instance.cacheWarehouses(warehouses);
      return warehouses;
    } catch (_) {
      final cached = await LocalDb.instance.getWarehouses();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<void> create(String name, {String? location}) async {
    await ref.read(apiClientProvider).post(ApiEndpoints.warehouses,
        body: {'name': name, if (location != null) 'location': location});
    ref.invalidateSelf();
  }
}

final warehouseListProvider = AsyncNotifierProvider<WarehouseListNotifier,
    List<Warehouse>>(WarehouseListNotifier.new);

/// Warehouse the app operates on (default from settings, else first).
final activeWarehouseProvider = Provider<Warehouse?>((ref) {
  final warehouses = ref.watch(warehouseListProvider).value ?? [];
  if (warehouses.isEmpty) return null;
  final preferred = ref.watch(
      appSettingsProvider.select((s) => s.value?.defaultWarehouseId));
  for (final w in warehouses) {
    if (w.id == preferred) return w;
  }
  return warehouses.first;
});

/// Stock levels for the active warehouse (with cache fallback).
final stockProvider = FutureProvider.autoDispose
    .family<List<StockEntry>, int>((ref, warehouseId) async {
  try {
    final data = await ref
        .read(apiClientProvider)
        .get(ApiEndpoints.warehouseStock(warehouseId)) as List;
    final stock =
        data.map((e) => StockEntry.fromJson(e as Map<String, dynamic>)).toList();
    await LocalDb.instance.cacheStock(stock);
    return stock;
  } catch (_) {
    final cached = await LocalDb.instance.getStock();
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
});

final movementsProvider =
    FutureProvider.autoDispose.family<List<StockMovement>, int>((ref, productId) async {
  final data = await ref
      .read(apiClientProvider)
      .get(ApiEndpoints.movements(productId)) as List;
  return data.map((e) => StockMovement.fromJson(e as Map<String, dynamic>)).toList();
});

/// Mutation helper used by inventory screens (add / deduct / transfer / adjust).
class InventoryActions {
  final Ref ref;
  InventoryActions(this.ref);

  ApiClient get _api => ref.read(apiClientProvider);

  Future<void> addStock({
    required int productId,
    required int warehouseId,
    required double quantity,
    String? note,
  }) =>
      _api.post(ApiEndpoints.inventoryAdd, body: {
        'productId': productId,
        'warehouseId': warehouseId,
        'quantity': quantity,
        if (note != null) 'note': note,
      });

  Future<void> deductStock({
    required int productId,
    required int warehouseId,
    required double quantity,
    String? note,
  }) =>
      _api.post(ApiEndpoints.inventoryDeduct, body: {
        'productId': productId,
        'warehouseId': warehouseId,
        'quantity': quantity,
        if (note != null) 'note': note,
      });

  Future<void> adjustStock({
    required int productId,
    required int warehouseId,
    required double newQuantity,
    String? note,
  }) =>
      _api.post(ApiEndpoints.inventoryAdjust, body: {
        'productId': productId,
        'warehouseId': warehouseId,
        'newQuantity': newQuantity,
        if (note != null) 'note': note,
      });

  Future<void> transfer({
    required int productId,
    required int fromWarehouseId,
    required int toWarehouseId,
    required double quantity,
    String? note,
  }) =>
      _api.post(ApiEndpoints.inventoryTransfer, body: {
        'productId': productId,
        'fromWarehouseId': fromWarehouseId,
        'toWarehouseId': toWarehouseId,
        'quantity': quantity,
        if (note != null) 'note': note,
      });
}

final inventoryActionsProvider = Provider<InventoryActions>(InventoryActions.new);
