import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../models/product.dart';

class CartState {
  final List<CartItem> items;
  final double discountPercent;
  final double taxPercent;

  const CartState({
    this.items = const [],
    this.discountPercent = 0,
    this.taxPercent = 0,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.base);
  double get discountAmount => items.fold(0, (sum, item) => sum + item.discountAmount);
  double get taxAmount => items.fold(0, (sum, item) => sum + item.taxAmount);
  double get grandTotal => items.fold(0, (sum, item) => sum + item.lineTotal);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity.round());
  bool get isEmpty => items.isEmpty;

  CartState copyWith({List<CartItem>? items, double? discountPercent, double? taxPercent}) =>
      CartState(
        items: items ?? this.items,
        discountPercent: discountPercent ?? this.discountPercent,
        taxPercent: taxPercent ?? this.taxPercent,
      );
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addItem(Product product) {
    final index = state.items.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      final updated = [...state.items];
      updated[index] =
          updated[index].copyWith(quantity: updated[index].quantity + 1);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [
        ...state.items,
        CartItem(
          productId: product.id,
          productName: product.name,
          sku: product.sku,
          unitPrice: product.sellingPrice,
          taxPercent: product.taxRate,
        ),
      ]);
    }
  }

  void addCartItem(CartItem item) => state =
      state.copyWith(items: [...state.items, item]);

  void updateQuantity(int productId, double quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final updated = state.items
        .map((item) =>
            item.productId == productId ? item.copyWith(quantity: quantity) : item)
        .toList();
    state = state.copyWith(items: updated);
  }

  void updatePrice(int productId, double price) {
    final updated = state.items
        .map((item) =>
            item.productId == productId ? item.copyWith(unitPrice: price) : item)
        .toList();
    state = state.copyWith(items: updated);
  }

  void removeItem(int productId) {
    state = state.copyWith(
        items: state.items.where((item) => item.productId != productId).toList());
  }

  void setDiscountPercent(double value) =>
      state = state.copyWith(discountPercent: value);

  void setTaxPercent(double value) => state = state.copyWith(taxPercent: value);

  void clear() => state = const CartState();

  /// Payload for POST /api/v1/sales/.
  Map<String, dynamic> toSalePayload({
    required int warehouseId,
    required double paidAmount,
    String paymentMethod = 'Cash',
    String? note,
  }) =>
      {
        'warehouse_id': warehouseId,
        'sale_type': 'POS',
        'status': 'Completed',
        if (state.discountPercent > 0) 'discount_percent': state.discountPercent,
        if (state.taxPercent > 0) 'tax_percent': state.taxPercent,
        if (note != null && note.isNotEmpty) 'note': note,
        'items': state.items.map((item) => item.toSaleItemJson()).toList(),
        if (paidAmount > 0)
          'payments': [
            {'amount': paidAmount, 'payment_method': paymentMethod}
          ],
      };
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
