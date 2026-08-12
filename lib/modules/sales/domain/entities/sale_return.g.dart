// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_return.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SaleReturnImpl _$$SaleReturnImplFromJson(Map<String, dynamic> json) =>
    _$SaleReturnImpl(
      id: (json['id'] as num?)?.toInt(),
      saleId: (json['saleId'] as num).toInt(),
      returnDate: json['returnDate'] == null
          ? null
          : DateTime.parse(json['returnDate'] as String),
      reason: json['reason'] as String?,
      restock: json['restock'] as bool? ?? false,
      refundAmount: (json['refundAmount'] as num?)?.toDouble() ?? 0,
      refundMethod: json['refundMethod'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$SaleReturnImplToJson(_$SaleReturnImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'saleId': instance.saleId,
      'returnDate': instance.returnDate?.toIso8601String(),
      'reason': instance.reason,
      'restock': instance.restock,
      'refundAmount': instance.refundAmount,
      'refundMethod': instance.refundMethod,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
