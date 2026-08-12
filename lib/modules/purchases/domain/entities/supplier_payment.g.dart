// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SupplierPaymentImpl _$$SupplierPaymentImplFromJson(
        Map<String, dynamic> json) =>
    _$SupplierPaymentImpl(
      id: (json['id'] as num?)?.toInt(),
      supplierId: (json['supplierId'] as num?)?.toInt(),
      purchaseId: (json['purchaseId'] as num?)?.toInt(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash',
      reference: json['reference'] as String?,
      paymentDate: json['paymentDate'] == null
          ? null
          : DateTime.parse(json['paymentDate'] as String),
      createdBy: (json['createdBy'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$SupplierPaymentImplToJson(
        _$SupplierPaymentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'supplierId': instance.supplierId,
      'purchaseId': instance.purchaseId,
      'amount': instance.amount,
      'paymentMethod': instance.paymentMethod,
      'reference': instance.reference,
      'paymentDate': instance.paymentDate?.toIso8601String(),
      'createdBy': instance.createdBy,
    };
