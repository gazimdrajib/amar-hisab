/// One POS cart line. Totals mirror the backend sale-item computation:
/// lineTotal = qty * unitPrice - (qty * unitPrice) * discount/100 + tax.
class CartItem {
  final int productId;
  final String productName;
  final String? sku;
  final double quantity;
  final double unitPrice;
  final double discountPercent;
  final double taxPercent;

  const CartItem({
    required this.productId,
    required this.productName,
    this.sku,
    this.quantity = 1,
    required this.unitPrice,
    this.discountPercent = 0,
    this.taxPercent = 0,
  });

  double get base => quantity * unitPrice;
  double get discountAmount => base * discountPercent / 100;
  double get taxableAmount => base - discountAmount;
  double get taxAmount => taxableAmount * taxPercent / 100;
  double get lineTotal => taxableAmount + taxAmount;

  CartItem copyWith({
    double? quantity,
    double? unitPrice,
    double? discountPercent,
    double? taxPercent,
  }) =>
      CartItem(
        productId: productId,
        productName: productName,
        sku: sku,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        discountPercent: discountPercent ?? this.discountPercent,
        taxPercent: taxPercent ?? this.taxPercent,
      );

  /// Body item for POST /api/v1/sales/ (snake_case accepted by backend).
  Map<String, dynamic> toSaleItemJson() => {
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
        if (discountPercent > 0) 'discount_percent': discountPercent,
        if (taxPercent > 0) 'tax_percent': taxPercent,
      };
}

enum PaymentMethod { cash, card, mobile, bank, credit }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.card => 'Card',
        PaymentMethod.mobile => 'Mobile Banking',
        PaymentMethod.bank => 'Bank Transfer',
        PaymentMethod.credit => 'Credit (Due)',
      };
}
