// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posting_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostingTemplateImpl _$$PostingTemplateImplFromJson(
        Map<String, dynamic> json) =>
    _$PostingTemplateImpl(
      id: (json['id'] as num?)?.toInt(),
      templateCode: json['templateCode'] as String,
      description: json['description'] as String?,
      businessId: (json['businessId'] as num).toInt(),
    );

Map<String, dynamic> _$$PostingTemplateImplToJson(
        _$PostingTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'templateCode': instance.templateCode,
      'description': instance.description,
      'businessId': instance.businessId,
    };
