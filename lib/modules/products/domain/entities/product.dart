import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    int? id,
    required int businessId,
    required String sku,
    String? barcode,
    required String name,
    String? description,
    int? categoryId,
    int? brandId,
    int? unitId,
    @Default(0) double purchasePrice,
    @Default(0) double sellingPrice,
    @Default(0) double taxRate,
    @Default(0) double minStockLevel,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
