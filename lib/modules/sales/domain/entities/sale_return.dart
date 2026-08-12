import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale_return.freezed.dart';
part 'sale_return.g.dart';

/// Return processed against a sale (Database Book §3.3 – `sales_returns`).
@freezed
class SaleReturn with _$SaleReturn {
  const factory SaleReturn({
    int? id,
    required int saleId,
    DateTime? returnDate,
    String? reason,
    @Default(false) bool restock,
    @Default(0) double refundAmount,
    String? refundMethod,
    DateTime? createdAt,
  }) = _SaleReturn;

  factory SaleReturn.fromJson(Map<String, dynamic> json) =>
      _$SaleReturnFromJson(json);
}
