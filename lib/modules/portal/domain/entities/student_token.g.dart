// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudentTokenImpl _$$StudentTokenImplFromJson(Map<String, dynamic> json) =>
    _$StudentTokenImpl(
      id: (json['id'] as num?)?.toInt(),
      businessId: (json['businessId'] as num).toInt(),
      token: json['token'] as String,
      type: json['type'] as String? ?? 'qr',
      studentId: (json['studentId'] as num?)?.toInt(),
      batchId: (json['batchId'] as num?)?.toInt(),
      secretHash: json['secretHash'] as String?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$StudentTokenImplToJson(_$StudentTokenImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'token': instance.token,
      'type': instance.type,
      'studentId': instance.studentId,
      'batchId': instance.batchId,
      'secretHash': instance.secretHash,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
