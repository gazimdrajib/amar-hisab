import '../entities/journal_line.dart';

abstract class JournalLineRepository {
  Future<List<JournalLine>> findByJournalEntry(int journalEntryId);
  Future<JournalLine> insert(JournalLine line);
}
