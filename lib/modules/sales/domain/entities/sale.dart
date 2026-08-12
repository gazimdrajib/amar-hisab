import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale.freezed.dart';
part 'sale.g.dart';

/// Sale header (Database Book §3.3 – `sales`).
@freezed
class Sale with _$Sale {
  const factory Sale({
    int? id,
    String? invoiceNumber,
    int? customerId,
    DateTime? saleDate,
    @Default('POS') String saleType,
    int? warehouseId,
    @Default(0) double totalAmount,
    @Default(0) double discountPercent,
    @Default(0) double discountAmount,
    @Default(0) double taxPercent,
    @Default(0) double taxAmount,
    @Default(0) double grandTotal,
    @Default(0) double paidAmount,
    @Default(0) double dueAmount,
    @Default('Completed') String status,
    @Default('Paid') String paymentStatus,
    String? note,
    required int businessId,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Sale;

  factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);
}
