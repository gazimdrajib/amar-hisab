import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/sale.dart';
import 'app_providers.dart';
import 'sales_providers.dart';

/// Imperative checkout: kicks off POST /api/v1/sales/ and reports result.
final checkoutControllerProvider =
    AutoDisposeAsyncNotifierProvider<CheckoutController, SaleDetail?>(
        CheckoutController.new);

class CheckoutController extends AutoDisposeAsyncNotifier<SaleDetail?> {
  @override
  Future<SaleDetail?> build() async => null;

  Future<SaleDetail> checkout(Map<String, dynamic> payload) async {
    state = const AsyncLoading();
    try {
      final data = await ref
          .read(apiClientProvider)
          .post(ApiEndpoints.sales, body: payload) as Map<String, dynamic>;
      final detail = SaleDetail.fromJson(data);
      ref.read(salesListProvider.notifier).refresh();
      state = AsyncData(detail);
      return detail;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
