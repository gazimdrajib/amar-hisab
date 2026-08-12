import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale_payment.freezed.dart';
part 'sale_payment.g.dart';

/// Payment recorded against a sale (Database Book §3.3 – `sale_payments`).
@freezed
class SalePayment with _$SalePayment {
  const factory SalePayment({
    int? id,
    int? saleId,
    @Default(0) double amount,
    @Default('Cash') String paymentMethod,
    String? reference,
    DateTime? paymentDate,
    int? createdBy,
  }) = _SalePayment;

  factory SalePayment.fromJson(Map<String, dynamic> json) =>
      _$SalePaymentFromJson(json);
}
