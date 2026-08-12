import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_item.freezed.dart';
part 'purchase_item.g.dart';

/// Line item of a purchase invoice (Database Book §3.4 – `purchase_items`).
@freezed
class PurchaseItem with _$PurchaseItem {
  const factory PurchaseItem({
    int? id,
    int? purchaseId,
    required int productId,
    @Default(0) double quantity,
    @Default(0) double unitPrice,
    @Default(0) double discountPercent,
    @Default(0) double discountAmount,
    @Default(0) double taxPercent,
    @Default(0) double taxAmount,
    @Default(0) double lineTotal,
  }) = _PurchaseItem;

  factory PurchaseItem.fromJson(Map<String, dynamic> json) =>
      _$PurchaseItemFromJson(json);
}
