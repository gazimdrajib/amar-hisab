// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountImpl _$$AccountImplFromJson(Map<String, dynamic> json) =>
    _$AccountImpl(
      id: (json['id'] as num?)?.toInt(),
      accountCode: json['accountCode'] as String,
      accountName: json['accountName'] as String,
      accountType: json['accountType'] as String,
      parentId: (json['parentId'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
      isSystem: json['isSystem'] as bool? ?? false,
      businessId: (json['businessId'] as num).toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$AccountImplToJson(_$AccountImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountCode': instance.accountCode,
      'accountName': instance.accountName,
      'accountType': instance.accountType,
      'parentId': instance.parentId,
      'isActive': instance.isActive,
      'isSystem': instance.isSystem,
      'businessId': instance.businessId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
