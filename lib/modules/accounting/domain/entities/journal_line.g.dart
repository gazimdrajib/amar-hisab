// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JournalLineImpl _$$JournalLineImplFromJson(Map<String, dynamic> json) =>
    _$JournalLineImpl(
      id: (json['id'] as num?)?.toInt(),
      journalEntryId: (json['journalEntryId'] as num?)?.toInt(),
      accountId: (json['accountId'] as num).toInt(),
      debit: (json['debit'] as num?)?.toDouble() ?? 0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$JournalLineImplToJson(_$JournalLineImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'journalEntryId': instance.journalEntryId,
      'accountId': instance.accountId,
      'debit': instance.debit,
      'credit': instance.credit,
      'description': instance.description,
    };
