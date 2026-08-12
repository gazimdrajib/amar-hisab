import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale_item.freezed.dart';
part 'sale_item.g.dart';

/// Line item of a sale (Database Book §3.3 – `sale_items`).
@freezed
class SaleItem with _$SaleItem {
  const factory SaleItem({
    int? id,
    int? saleId,
    required int productId,
    @Default(0) double quantity,
    @Default(0) double unitPrice,
    @Default(0) double discountPercent,
    @Default(0) double discountAmount,
    @Default(0) double taxPercent,
    @Default(0) double taxAmount,
    @Default(0) double lineTotal,
  }) = _SaleItem;

  factory SaleItem.fromJson(Map<String, dynamic> json) =>
      _$SaleItemFromJson(json);
}
