// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BatchImpl _$$BatchImplFromJson(Map<String, dynamic> json) => _$BatchImpl(
      id: (json['id'] as num?)?.toInt(),
      businessId: (json['businessId'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      warehouseId: (json['warehouseId'] as num).toInt(),
      batchNumber: json['batchNumber'] as String?,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$BatchImplToJson(_$BatchImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'productId': instance.productId,
      'warehouseId': instance.warehouseId,
      'batchNumber': instance.batchNumber,
      'purchasePrice': instance.purchasePrice,
      'expiryDate': instance.expiryDate?.toIso8601String(),
      'receivedAt': instance.receivedAt.toIso8601String(),
      'quantity': instance.quantity,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
