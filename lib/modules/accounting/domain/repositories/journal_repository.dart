import '../entities/journal_entry.dart';
import '../entities/journal_line.dart';

/// Composite detail: journal header + lines.
class JournalDetail {
  const JournalDetail({
    required this.entry,
    this.lines = const [],
  });

  final JournalEntry entry;
  final List<JournalLine> lines;

  Map<String, dynamic> toJson() => {
        ...entry.toJson(),
        'lines': lines.map((l) => l.toJson()).toList(),
      };
}

abstract class JournalRepository {
  /// Insert header + lines; returns the id-filled header.
  /// Caller manages the surrounding transaction.
  Future<JournalEntry> insert(
      JournalEntry entry, List<JournalLine> lines);

  Future<JournalEntry?> findById(int id);
  Future<JournalDetail?> getDetail(int id);

  Future<List<JournalEntry>> list(
    int businessId, {
    String? fromDate,
    String? toDate,
    int? accountId,
    String? status,
    int limit = 50,
    int offset = 0,
  });

  /// Update mutable fields (only allowed for draft entries).
  Future<JournalEntry> update(JournalEntry entry);

  /// Set status to 'posted' (immutable after this).
  Future<JournalEntry> post(int id);
}
