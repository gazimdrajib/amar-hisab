// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StockMovementImpl _$$StockMovementImplFromJson(Map<String, dynamic> json) =>
    _$StockMovementImpl(
      id: (json['id'] as num?)?.toInt(),
      businessId: (json['businessId'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      warehouseId: (json['warehouseId'] as num).toInt(),
      batchId: (json['batchId'] as num?)?.toInt(),
      movementType: json['movementType'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      referenceType: json['referenceType'] as String?,
      referenceId: (json['referenceId'] as num?)?.toInt(),
      note: json['note'] as String?,
      performedBy: (json['performedBy'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$StockMovementImplToJson(_$StockMovementImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'productId': instance.productId,
      'warehouseId': instance.warehouseId,
      'batchId': instance.batchId,
      'movementType': instance.movementType,
      'quantity': instance.quantity,
      'referenceType': instance.referenceType,
      'referenceId': instance.referenceId,
      'note': instance.note,
      'performedBy': instance.performedBy,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
