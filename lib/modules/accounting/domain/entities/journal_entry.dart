import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

/// Journal entry header (Database Book §3.5 – `journal_entries`).
@freezed
class JournalEntry with _$JournalEntry {
  const factory JournalEntry({
    int? id,
    required String entryNumber,
    required DateTime entryDate,
    String? reference,
    String? note,
    @Default(false) bool isAuto,
    @Default('posted') String status, // 'draft' or 'posted'
    required int businessId,
    int? createdBy,
    DateTime? createdAt,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);
}
