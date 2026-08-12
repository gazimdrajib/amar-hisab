// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PurchaseImpl _$$PurchaseImplFromJson(Map<String, dynamic> json) =>
    _$PurchaseImpl(
      id: (json['id'] as num?)?.toInt(),
      invoiceNumber: json['invoiceNumber'] as String?,
      supplierId: (json['supplierId'] as num?)?.toInt(),
      purchaseDate: json['purchaseDate'] == null
          ? null
          : DateTime.parse(json['purchaseDate'] as String),
      warehouseId: (json['warehouseId'] as num?)?.toInt(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      dueAmount: (json['dueAmount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'Received',
      paymentStatus: json['paymentStatus'] as String? ?? 'Paid',
      note: json['note'] as String?,
      businessId: (json['businessId'] as num).toInt(),
      createdBy: (json['createdBy'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$PurchaseImplToJson(_$PurchaseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoiceNumber': instance.invoiceNumber,
      'supplierId': instance.supplierId,
      'purchaseDate': instance.purchaseDate?.toIso8601String(),
      'warehouseId': instance.warehouseId,
      'totalAmount': instance.totalAmount,
      'discountPercent': instance.discountPercent,
      'discountAmount': instance.discountAmount,
      'taxPercent': instance.taxPercent,
      'taxAmount': instance.taxAmount,
      'grandTotal': instance.grandTotal,
      'paidAmount': instance.paidAmount,
      'dueAmount': instance.dueAmount,
      'status': instance.status,
      'paymentStatus': instance.paymentStatus,
      'note': instance.note,
      'businessId': instance.businessId,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
