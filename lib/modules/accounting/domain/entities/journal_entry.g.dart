// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JournalEntryImpl _$$JournalEntryImplFromJson(Map<String, dynamic> json) =>
    _$JournalEntryImpl(
      id: (json['id'] as num?)?.toInt(),
      entryNumber: json['entryNumber'] as String,
      entryDate: DateTime.parse(json['entryDate'] as String),
      reference: json['reference'] as String?,
      note: json['note'] as String?,
      isAuto: json['isAuto'] as bool? ?? false,
      status: json['status'] as String? ?? 'posted',
      businessId: (json['businessId'] as num).toInt(),
      createdBy: (json['createdBy'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$JournalEntryImplToJson(_$JournalEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'entryNumber': instance.entryNumber,
      'entryDate': instance.entryDate.toIso8601String(),
      'reference': instance.reference,
      'note': instance.note,
      'isAuto': instance.isAuto,
      'status': instance.status,
      'businessId': instance.businessId,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
