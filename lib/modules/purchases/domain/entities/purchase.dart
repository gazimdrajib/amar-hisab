import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase.freezed.dart';
part 'purchase.g.dart';

/// Purchase invoice header (Database Book §3.4 – `purchases`).
@freezed
class Purchase with _$Purchase {
  const factory Purchase({
    int? id,
    String? invoiceNumber,
    int? supplierId,
    DateTime? purchaseDate,
    int? warehouseId,
    @Default(0) double totalAmount,
    @Default(0) double discountPercent,
    @Default(0) double discountAmount,
    @Default(0) double taxPercent,
    @Default(0) double taxAmount,
    @Default(0) double grandTotal,
    @Default(0) double paidAmount,
    @Default(0) double dueAmount,
    @Default('Received') String status,
    @Default('Paid') String paymentStatus,
    String? note,
    required int businessId,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Purchase;

  factory Purchase.fromJson(Map<String, dynamic> json) =>
      _$PurchaseFromJson(json);
}
