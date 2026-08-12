import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/storage/local_db.dart';
import '../models/purchase.dart';
import 'app_providers.dart';

class PurchasesListNotifier extends AsyncNotifier<List<Purchase>> {
  @override
  Future<List<Purchase>> build() => _load();

  Future<List<Purchase>> _load() async {
    try {
      final data = await ref
          .read(apiClientProvider)
          .get(ApiEndpoints.purchases, query: {'limit': 200}) as List;
      final purchases = data
          .map((e) => Purchase.fromJson(e as Map<String, dynamic>))
          .toList();
      await LocalDb.instance.cachePurchases(purchases);
      return purchases;
    } catch (_) {
      final cached = await LocalDb.instance.getPurchases();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

final purchasesListProvider = AsyncNotifierProvider<PurchasesListNotifier,
    List<Purchase>>(PurchasesListNotifier.new);

final purchaseDetailProvider =
    FutureProvider.family<Purchase, int>((ref, id) async {
  final data = await ref
      .read(apiClientProvider)
      .get('${ApiEndpoints.purchases}$id') as Map<String, dynamic>;
  return Purchase.fromJson(data);
});

/// Supplier due/partial purchases for dashboard reminders.
final duePurchasesProvider = FutureProvider<List<Purchase>>((ref) async {
  final api = ref.read(apiClientProvider);
  final result = <Purchase>[];
  for (final status in ['Due', 'Partial']) {
    try {
      final data = await api.get(ApiEndpoints.purchases, query: {
        'payment_status': status,
        'limit': 50,
      }) as List;
      result.addAll(
          data.map((e) => Purchase.fromJson(e as Map<String, dynamic>)));
    } catch (_) {/* ignore offline */}
  }
  result.sort((a, b) => b.dueAmount.compareTo(a.dueAmount));
  return result;
});
