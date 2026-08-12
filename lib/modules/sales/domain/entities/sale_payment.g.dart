// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SalePaymentImpl _$$SalePaymentImplFromJson(Map<String, dynamic> json) =>
    _$SalePaymentImpl(
      id: (json['id'] as num?)?.toInt(),
      saleId: (json['saleId'] as num?)?.toInt(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash',
      reference: json['reference'] as String?,
      paymentDate: json['paymentDate'] == null
          ? null
          : DateTime.parse(json['paymentDate'] as String),
      createdBy: (json['createdBy'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$SalePaymentImplToJson(_$SalePaymentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'saleId': instance.saleId,
      'amount': instance.amount,
      'paymentMethod': instance.paymentMethod,
      'reference': instance.reference,
      'paymentDate': instance.paymentDate?.toIso8601String(),
      'createdBy': instance.createdBy,
    };
