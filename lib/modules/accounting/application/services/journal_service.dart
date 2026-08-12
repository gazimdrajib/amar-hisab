import '../../../../core/events/domain_event.dart';
import '../../../../core/services/audit_service.dart';
import '../../../../core/services/change_log_service.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/journal_line.dart';
import '../../domain/events/accounting_events.dart';
import '../../domain/repositories/journal_repository.dart';

/// Error raised by [JournalService]; carries a machine-readable [code] the
/// controller maps to an HTTP status.
class JournalServiceException implements Exception {
  const JournalServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'JournalServiceException($code): $message';
}

/// Lookup chart-of-accounts ID by [accountName] for [businessId].
/// Returns 0 when not found (caller decides how to handle).
typedef AccountLookup = Future<int> Function(int businessId, String accountName);

/// Double-entry journal engine (Architecture Book §13.5, §14.2).
///
///  * [createJournal] – validates debits == credits, persists draft.
///  * [postJournal] – finalises a draft; posted entries are immutable.
///  * [createAndPost] – convenience for auto-posting (used by SalesService / PurchaseService).
class JournalService {
  JournalService(this._journalRepo, this._audit, this._events,
      {ChangeLogService? changeLog})
      : _changeLog = changeLog;

  final JournalRepository _journalRepo;
  final AuditService _audit;
  final EventBus _events;
  final ChangeLogService? _changeLog;

  static const double _eps = 0.0001;

  // -- Queries -------------------------------------------------------------

  Future<JournalDetail?> getJournal(int businessId, int id) async {
    final detail = await _journalRepo.getDetail(id);
    if (detail == null || detail.entry.businessId != businessId) return null;
    return detail;
  }

  Future<List<JournalEntry>> listJournals(
    int businessId, {
    String? fromDate,
    String? toDate,
    int? accountId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) =>
      _journalRepo.list(
        businessId,
        fromDate: fromDate,
        toDate: toDate,
        accountId: accountId,
        status: status,
        limit: limit,
        offset: offset,
      );

  // -- Commands -------------------------------------------------------------

  /// Create a draft journal entry. Debits must equal credits.
  Future<JournalEntry> createJournal({
    required int businessId,
    required DateTime entryDate,
    String? reference,
    String? note,
    required List<JournalLine> lines,
    required int actorId,
  }) async {
    _validateBalanced(lines);

    final entryNumber =
        'JE-${DateTime.now().year}-${DateTime.now().microsecondsSinceEpoch}';
    final entry = await _journalRepo.insert(
      JournalEntry(
        entryNumber: entryNumber,
        entryDate: entryDate,
        reference: reference,
        note: note,
        isAuto: false,
        status: 'draft',
        businessId: businessId,
        createdBy: actorId,
      ),
      lines,
    );

    _recordJournalChange(entry, lines, businessId);

    _audit.logAction(
      userId: actorId,
      entityType: 'journal_entry',
      entityId: entry.id!,
      action: 'create',
      newValue: 'number=$entryNumber; status=draft',
      businessId: businessId,
    );
    return entry;
  }

  /// Post a draft journal entry (immutable after this).
  Future<JournalEntry> postJournal({
    required int businessId,
    required int id,
    required int actorId,
  }) async {
    final detail = await _journalRepo.getDetail(id);
    if (detail == null || detail.entry.businessId != businessId) {
      throw const JournalServiceException('not_found', 'Journal entry not found');
    }
    if (detail.entry.status == 'posted') {
      throw const JournalServiceException(
          'already_posted', 'Journal entry is already posted');
    }

    _validateBalanced(detail.lines);
    final posted = await _journalRepo.post(id);

    _audit.logAction(
      userId: actorId,
      entityType: 'journal_entry',
      entityId: id,
      action: 'post',
      oldValue: 'status=draft',
      newValue: 'status=posted',
      businessId: businessId,
    );

    // Publish AFTER commit (Architecture Book §16.2).
    _events.publish(JournalPosted(
      entryId: posted.id!,
      entryNumber: posted.entryNumber,
      isAuto: posted.isAuto,
      reference: posted.reference,
      businessId: businessId,
    ));
    return posted;
  }

  /// Convenience: create and immediately post an auto journal entry.
  /// Used by SalesService, PurchaseService, InventoryService, etc.
  Future<JournalEntry> createAndPost({
    required int businessId,
    required DateTime entryDate,
    String? reference,
    String? note,
    required List<JournalLine> lines,
    required int actorId,
  }) async {
    _validateBalanced(lines);

    final entryNumber =
        'JE-${DateTime.now().year}-${DateTime.now().microsecondsSinceEpoch}';
    final entry = await _journalRepo.insert(
      JournalEntry(
        entryNumber: entryNumber,
        entryDate: entryDate,
        reference: reference,
        note: note,
        isAuto: true,
        status: 'posted',
        businessId: businessId,
        createdBy: actorId,
      ),
      lines,
    );

    _recordJournalChange(entry, lines, businessId);

    _audit.logAction(
      userId: actorId,
      entityType: 'journal_entry',
      entityId: entry.id!,
      action: 'create',
      newValue: 'number=$entryNumber; status=posted; auto=true',
      businessId: businessId,
    );

    _events.publish(JournalPosted(
      entryId: entry.id!,
      entryNumber: entry.entryNumber,
      isAuto: true,
      reference: entry.reference,
      businessId: businessId,
    ));
    return entry;
  }

  // -- Internals -------------------------------------------------------------

  /// Transactional outbox (Event Catalog §4.2 – `journal_entry` INSERT):
  /// payload contains the entry header plus all lines.
  void _recordJournalChange(
      JournalEntry entry, List<JournalLine> lines, int businessId) {
    _changeLog?.recordChange(
      entityType: 'journal_entry',
      entityId: entry.id!,
      operation: ChangeOperation.insert,
      payload: {
        'id': entry.id,
        'entry_number': entry.entryNumber,
        'entry_date': entry.entryDate.toIso8601String(),
        'reference': entry.reference,
        'note': entry.note,
        'is_auto': entry.isAuto,
        'status': entry.status,
        'business_id': entry.businessId,
        'created_by': entry.createdBy,
        'lines': [
          for (final line in lines)
            {
              'account_id': line.accountId,
              'debit': line.debit,
              'credit': line.credit,
              'description': line.description,
            },
        ],
      },
      businessId: businessId,
    );
  }

  void _validateBalanced(List<JournalLine> lines) {
    if (lines.isEmpty) {
      throw const JournalServiceException(
          'empty_journal', 'Journal entry must contain at least one line');
    }
    final debit =
        lines.fold<double>(0, (sum, line) => sum + line.debit);
    final credit =
        lines.fold<double>(0, (sum, line) => sum + line.credit);
    if ((debit - credit).abs() > _eps) {
      throw const JournalServiceException(
          'unbalanced', 'Total debits must equal total credits');
    }
    for (final line in lines) {
      if (line.debit <= 0 && line.credit <= 0) {
        throw const JournalServiceException(
            'invalid_line', 'Each line must have a debit or credit > 0');
      }
    }
  }
}
