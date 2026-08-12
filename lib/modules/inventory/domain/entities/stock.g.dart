// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StockImpl _$$StockImplFromJson(Map<String, dynamic> json) => _$StockImpl(
      id: (json['id'] as num?)?.toInt(),
      businessId: (json['businessId'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      warehouseId: (json['warehouseId'] as num).toInt(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$StockImplToJson(_$StockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'productId': instance.productId,
      'warehouseId': instance.warehouseId,
      'quantity': instance.quantity,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
