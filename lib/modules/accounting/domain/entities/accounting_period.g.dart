// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounting_period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountingPeriodImpl _$$AccountingPeriodImplFromJson(
        Map<String, dynamic> json) =>
    _$AccountingPeriodImpl(
      id: (json['id'] as num?)?.toInt(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isClosed: json['isClosed'] as bool? ?? false,
      businessId: (json['businessId'] as num).toInt(),
    );

Map<String, dynamic> _$$AccountingPeriodImplToJson(
        _$AccountingPeriodImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'isClosed': instance.isClosed,
      'businessId': instance.businessId,
    };
