import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/journal_line.dart';
import '../../domain/repositories/journal_line_repository.dart';

/// SQLite implementation of [JournalLineRepository].
class JournalLineRepositoryImpl implements JournalLineRepository {
  JournalLineRepositoryImpl(this._db);

  final Database _db;

  JournalLine _fromRow(Map<String, Object?> r) {
    double d(Object? v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
    return JournalLine(
      id: r['id'] as int?,
      journalEntryId: r['journal_entry_id'] as int?,
      accountId: r['account_id'] as int,
      debit: d(r['debit']),
      credit: d(r['credit']),
      description: r['description'] as String?,
    );
  }

  @override
  Future<List<JournalLine>> findByJournalEntry(int journalEntryId) async {
    final rows = _db.select(
      'SELECT * FROM journal_lines WHERE journal_entry_id = ? ORDER BY id;',
      [journalEntryId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<JournalLine> insert(JournalLine line) async {
    _db.execute(
      'INSERT INTO journal_lines '
      '(journal_entry_id, account_id, debit, credit, description) '
      'VALUES (?, ?, ?, ?, ?);',
      [
        line.journalEntryId,
        line.accountId,
        line.debit,
        line.credit,
        line.description,
      ],
    );
    return line.copyWith(id: _db.lastInsertRowId);
  }
}
