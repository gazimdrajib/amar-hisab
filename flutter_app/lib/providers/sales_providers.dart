import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/storage/local_db.dart';
import '../models/sale.dart';
import 'app_providers.dart';

class SalesListNotifier extends AsyncNotifier<List<Sale>> {
  @override
  Future<List<Sale>> build() => _load();

  Future<List<Sale>> _load() async {
    try {
      final data = await ref
          .read(apiClientProvider)
          .get(ApiEndpoints.sales, query: {'limit': 200}) as List;
      final sales =
          data.map((e) => Sale.fromJson(e as Map<String, dynamic>)).toList();
      await LocalDb.instance.cacheSales(sales);
      return sales;
    } catch (_) {
      final cached = await LocalDb.instance.getSales();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

final salesListProvider =
    AsyncNotifierProvider<SalesListNotifier, List<Sale>>(SalesListNotifier.new);

final saleDetailProvider =
    FutureProvider.family<SaleDetail, int>((ref, id) async {
  final data = await ref.read(apiClientProvider).get(ApiEndpoints.sale(id))
      as Map<String, dynamic>;
  return SaleDetail.fromJson(data);
});

/// Sales in Due/Partial payment state (dashboard due reminders).
final dueSalesProvider = FutureProvider<List<Sale>>((ref) async {
  final api = ref.read(apiClientProvider);
  final result = <Sale>[];
  for (final status in ['Due', 'Partial']) {
    try {
      final data = await api.get(ApiEndpoints.sales, query: {
        'payment_status': status,
        'limit': 50,
      }) as List;
      result.addAll(data.map((e) => Sale.fromJson(e as Map<String, dynamic>)));
    } catch (_) {/* ignore offline */}
  }
  result.sort((a, b) => b.dueAmount.compareTo(a.dueAmount));
  return result;
});
