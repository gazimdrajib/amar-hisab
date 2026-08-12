// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SaleImpl _$$SaleImplFromJson(Map<String, dynamic> json) => _$SaleImpl(
      id: (json['id'] as num?)?.toInt(),
      invoiceNumber: json['invoiceNumber'] as String?,
      customerId: (json['customerId'] as num?)?.toInt(),
      saleDate: json['saleDate'] == null
          ? null
          : DateTime.parse(json['saleDate'] as String),
      saleType: json['saleType'] as String? ?? 'POS',
      warehouseId: (json['warehouseId'] as num?)?.toInt(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      dueAmount: (json['dueAmount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'Completed',
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

Map<String, dynamic> _$$SaleImplToJson(_$SaleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoiceNumber': instance.invoiceNumber,
      'customerId': instance.customerId,
      'saleDate': instance.saleDate?.toIso8601String(),
      'saleType': instance.saleType,
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
