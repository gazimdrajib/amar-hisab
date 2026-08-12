import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/journal_line.dart';
import '../../domain/repositories/journal_line_repository.dart';
import '../../domain/repositories/journal_repository.dart';

/// SQLite implementation of [JournalRepository]. Parameterised queries only;
/// the caller (JournalService) owns the surrounding transaction.
class JournalRepositoryImpl implements JournalRepository {
  JournalRepositoryImpl(this._db, this._lineRepo);

  final Database _db;
  final JournalLineRepository _lineRepo;

  // -- Mapper ---------------------------------------------------------------
  JournalEntry _fromRow(Map<String, Object?> r) {
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return JournalEntry(
      id: r['id'] as int?,
      entryNumber: r['entry_number'] as String,
      entryDate: dt(r['entry_date']) ?? DateTime.now(),
      reference: r['reference'] as String?,
      note: r['note'] as String?,
      isAuto: (r['is_auto'] as int?) == 1,
      status: (r['status'] as String?) ?? 'posted',
      businessId: r['business_id'] as int,
      createdBy: r['created_by'] as int?,
      createdAt: dt(r['created_at']),
    );
  }

  @override
  Future<JournalEntry> insert(
      JournalEntry entry, List<JournalLine> lines) async {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO journal_entries '
      '(entry_number, entry_date, reference, note, is_auto, status, '
      ' business_id, created_by, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        entry.entryNumber,
        entry.entryDate.toIso8601String().substring(0, 10),
        entry.reference,
        entry.note,
        entry.isAuto ? 1 : 0,
        entry.status,
        entry.businessId,
        entry.createdBy,
        now,
      ],
    );
    final entryId = _db.lastInsertRowId;
    for (final line in lines) {
      await _lineRepo.insert(line.copyWith(journalEntryId: entryId));
    }
    return (await findById(entryId))!;
  }

  @override
  Future<JournalEntry?> findById(int id) async {
    final rows =
        _db.select('SELECT * FROM journal_entries WHERE id = ?;', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<JournalDetail?> getDetail(int id) async {
    final entry = await findById(id);
    if (entry == null) return null;
    return JournalDetail(
      entry: entry,
      lines: await _lineRepo.findByJournalEntry(id),
    );
  }

  @override
  Future<List<JournalEntry>> list(
    int businessId, {
    String? fromDate,
    String? toDate,
    int? accountId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final where = StringBuffer('je.business_id = ?');
    final args = <Object?>[businessId];
    if (fromDate != null) {
      where.write(' AND je.entry_date >= ?');
      args.add(fromDate);
    }
    if (toDate != null) {
      where.write(' AND je.entry_date <= ?');
      args.add(toDate);
    }
    if (accountId != null) {
      where.write(
          ' AND je.id IN (SELECT journal_entry_id FROM journal_lines WHERE account_id = ?)');
      args.add(accountId);
    }
    if (status != null) {
      where.write(' AND je.status = ?');
      args.add(status);
    }
    args.add(limit);
    args.add(offset);
    final rows = _db.select(
      'SELECT je.* FROM journal_entries je WHERE $where '
      'ORDER BY entry_date DESC, id DESC LIMIT ? OFFSET ?;',
      args,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<JournalEntry> update(JournalEntry entry) async {
    _db.execute(
      'UPDATE journal_entries SET entry_date = ?, reference = ?, note = ?, '
      'status = ? WHERE id = ?;',
      [
        entry.entryDate.toIso8601String().substring(0, 10),
        entry.reference,
        entry.note,
        entry.status,
        entry.id,
      ],
    );
    return (await findById(entry.id!))!;
  }

  @override
  Future<JournalEntry> post(int id) async {
    _db.execute(
      "UPDATE journal_entries SET status = 'posted' WHERE id = ?;",
      [id],
    );
    return (await findById(id))!;
  }
}
