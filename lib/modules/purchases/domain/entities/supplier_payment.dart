import 'package:freezed_annotation/freezed_annotation.dart';

part 'supplier_payment.freezed.dart';
part 'supplier_payment.g.dart';

/// Payment made to a supplier against a purchase invoice
/// (Database Book §3.4 – `supplier_payments`).
@freezed
class SupplierPayment with _$SupplierPayment {
  const factory SupplierPayment({
    int? id,
    int? supplierId,
    int? purchaseId,
    @Default(0) double amount,
    @Default('Cash') String paymentMethod,
    String? reference,
    DateTime? paymentDate,
    int? createdBy,
  }) = _SupplierPayment;

  factory SupplierPayment.fromJson(Map<String, dynamic> json) =>
      _$SupplierPaymentFromJson(json);
}
