import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/local_db.dart';
import '../models/product.dart';
import 'app_providers.dart';

/// Products — network first with sqflite cache fallback.
class ProductListNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() => _load();

  Future<List<Product>> _load() async {
    final api = ref.read(apiClientProvider);
    try {
      final data = await api.get(ApiEndpoints.products) as List;
      final products = data
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      await LocalDb.instance.cacheProducts(products);
      await LocalDb.instance.setSyncTime('products', DateTime.now());
      return products;
    } on ApiException {
      final cached = await LocalDb.instance.getProducts();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<Product>> search(String query) async {
    final api = ref.read(apiClientProvider);
    try {
      final data =
          await api.get(ApiEndpoints.productSearch(Uri.encodeComponent(query)))
              as List;
      return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return LocalDb.instance.getProducts(search: query);
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await ref.read(apiClientProvider).post(ApiEndpoints.products, body: payload);
    await refresh();
  }

  Future<void> edit(int id, Map<String, dynamic> payload) async {
    await ref.read(apiClientProvider).put(ApiEndpoints.product(id), body: payload);
    await refresh();
  }

  Future<void> delete(int id) async {
    await ref.read(apiClientProvider).delete(ApiEndpoints.product(id));
    await refresh();
  }
}

final productListProvider =
    AsyncNotifierProvider<ProductListNotifier, List<Product>>(ProductListNotifier.new);

/// Barcode lookup: local cache first, then server search fallback.
final barcodeLookupProvider =
    FutureProvider.family<Product?, String>((ref, barcode) async {
  final cached = await LocalDb.instance.findByBarcode(barcode);
  if (cached != null) return cached;
  try {
    final results = await ref.read(productListProvider.notifier).search(barcode);
    for (final p in results) {
      if (p.barcode == barcode) return p;
    }
  } catch (_) {}
  return null;
});

// ---------------------------------------------------------------------------

class CategoryListNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final data = await ref.read(apiClientProvider).get(ApiEndpoints.categories) as List;
    return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create(String name, {String? description}) async {
    await ref.read(apiClientProvider).post(ApiEndpoints.categories,
        body: {'name': name, if (description != null) 'description': description});
    ref.invalidateSelf();
  }
}

final categoryListProvider = AsyncNotifierProvider<CategoryListNotifier, List<Category>>(
    CategoryListNotifier.new);

class BrandListNotifier extends AsyncNotifier<List<Brand>> {
  @override
  Future<List<Brand>> build() async {
    final data = await ref.read(apiClientProvider).get(ApiEndpoints.brands) as List;
    return data.map((e) => Brand.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create(String name, {String? description}) async {
    await ref.read(apiClientProvider).post(ApiEndpoints.brands,
        body: {'name': name, if (description != null) 'description': description});
    ref.invalidateSelf();
  }
}

final brandListProvider =
    AsyncNotifierProvider<BrandListNotifier, List<Brand>>(BrandListNotifier.new);

class UnitListNotifier extends AsyncNotifier<List<Unit>> {
  @override
  Future<List<Unit>> build() async {
    final data = await ref.read(apiClientProvider).get(ApiEndpoints.units) as List;
    return data.map((e) => Unit.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create(String name, String abbreviation) async {
    await ref.read(apiClientProvider)
        .post(ApiEndpoints.units, body: {'name': name, 'abbreviation': abbreviation});
    ref.invalidateSelf();
  }
}

final unitListProvider =
    AsyncNotifierProvider<UnitListNotifier, List<Unit>>(UnitListNotifier.new);
