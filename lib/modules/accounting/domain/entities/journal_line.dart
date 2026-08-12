import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal_line.freezed.dart';
part 'journal_line.g.dart';

/// Journal entry line (Database Book §3.5 – `journal_lines`).
@freezed
class JournalLine with _$JournalLine {
  const factory JournalLine({
    int? id,
    int? journalEntryId,
    required int accountId,
    @Default(0) double debit,
    @Default(0) double credit,
    String? description,
  }) = _JournalLine;

  factory JournalLine.fromJson(Map<String, dynamic> json) =>
      _$JournalLineFromJson(json);
}
