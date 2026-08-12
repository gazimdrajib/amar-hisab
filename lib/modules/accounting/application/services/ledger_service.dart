import 'package:sqlite3/sqlite3.dart';

import '../../../../core/services/audit_service.dart';
import '../../domain/repositories/journal_line_repository.dart';

/// Error raised by [LedgerService]; carries a machine-readable [code] the
/// controller maps to an HTTP status.
class LedgerServiceException implements Exception {
  const LedgerServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'LedgerServiceException($code): $message';
}

/// Financial reporting queries (Architecture Book §14.2 – ledger, trial balance, P&L, balance sheet).
class LedgerService {
  // ignore: unused_field
  final JournalLineRepository _lineRepo;
  // ignore: unused_field
  final AuditService _audit;

  final Database _db;

  LedgerService(this._db, this._lineRepo, this._audit);

  // -- Ledger (account detail) ------------------------------------------------

  /// Account ledger with running balance.
  Future<List<Map<String, dynamic>>> getLedger(
    int businessId,
    int accountId, {
    String? fromDate,
    String? toDate,
  }) async {
    final where = StringBuffer('''
      jl.account_id = ?
      AND je.business_id = ?
      AND je.status = 'posted'
    ''');
    final args = <Object?>[accountId, businessId];
    if (fromDate != null) {
      where.write(' AND je.entry_date >= ?');
      args.add(fromDate);
    }
    if (toDate != null) {
      where.write(' AND je.entry_date <= ?');
      args.add(toDate);
    }
    final rows = _db.select('''
      SELECT
        je.entry_date,
        je.reference,
        je.entry_number,
        jl.debit,
        jl.credit,
        jl.description
      FROM journal_lines jl
      JOIN journal_entries je ON je.id = jl.journal_entry_id
      WHERE $where
      ORDER BY je.entry_date, jl.id;
    ''', args);

    var balance = 0.0;
    final ledger = <Map<String, dynamic>>[];
    for (final row in rows) {
      final debit = (row['debit'] as num?)?.toDouble() ?? 0;
      final credit = (row['credit'] as num?)?.toDouble() ?? 0;
      balance += debit - credit;
      ledger.add({
        'date': row['entry_date'],
        'reference': row['reference'],
        'entry_number': row['entry_number'],
        'debit': debit,
        'credit': credit,
        'description': row['description'],
        'balance': balance,
      });
    }
    return ledger;
  }

  // -- Trial Balance -----------------------------------------------------------

  /// Trial balance: debit/credit totals per account up to [asOfDate].
  Future<List<Map<String, dynamic>>> getTrialBalance(
    int businessId, {
    String? asOfDate,
  }) async {
    // je filters live in the JOIN's ON clause so accounts with no journal
    // activity still appear (LEFT JOIN). Parameterised throughout.
    final onParts = <String>["je.status = 'posted'", 'je.business_id = ?'];
    final args = <Object?>[businessId];
    if (asOfDate != null) {
      onParts.add('je.entry_date <= ?');
      args.add(asOfDate);
    }
    final joinFilter = onParts.join(' AND ');
    final rows = _db.select('''
      SELECT
        coa.id AS account_id,
        coa.account_code,
        coa.account_name,
        coa.account_type,
        COALESCE(SUM(jl.debit), 0) AS total_debit,
        COALESCE(SUM(jl.credit), 0) AS total_credit
      FROM chart_of_accounts coa
      LEFT JOIN journal_lines jl ON jl.account_id = coa.id
      LEFT JOIN journal_entries je ON je.id = jl.journal_entry_id AND $joinFilter
      WHERE coa.business_id = ?
      GROUP BY coa.id
      ORDER BY coa.account_code;
    ''', [...args, businessId]);
    return rows
        .map((r) => {
              'account_id': r['account_id'],
              'account_code': r['account_code'],
              'account_name': r['account_name'],
              'account_type': r['account_type'],
              'debit': (r['total_debit'] as num?)?.toDouble() ?? 0,
              'credit': (r['total_credit'] as num?)?.toDouble() ?? 0,
            })
        .toList();
  }

  // -- Profit & Loss ------------------------------------------------------------

  /// Profit & Loss statement for a date range.
  Future<Map<String, dynamic>> getProfitLoss(
    int businessId, {
    String? fromDate,
    String? toDate,
  }) async {
    final where = StringBuffer('''
      je.business_id = ?
      AND je.status = 'posted'
      AND coa.account_type IN ('Revenue', 'Expense')
    ''');
    final args = <Object?>[businessId];
    if (fromDate != null) {
      where.write(' AND je.entry_date >= ?');
      args.add(fromDate);
    }
    if (toDate != null) {
      where.write(' AND je.entry_date <= ?');
      args.add(toDate);
    }
    final rows = _db.select('''
      SELECT
        coa.account_type,
        COALESCE(SUM(jl.credit - jl.debit), 0) AS amount
      FROM journal_lines jl
      JOIN journal_entries je ON je.id = jl.journal_entry_id
      JOIN chart_of_accounts coa ON coa.id = jl.account_id
      WHERE $where
      GROUP BY coa.account_type;
    ''', args);

    double revenue = 0;
    double expenses = 0;
    for (final row in rows) {
      final amount = (row['amount'] as num?)?.toDouble() ?? 0;
      if (row['account_type'] == 'Revenue') {
        revenue += amount;
      } else if (row['account_type'] == 'Expense') {
        expenses += amount;
      }
    }
    return {
      'revenue': revenue,
      'expenses': expenses,
      'net_profit': revenue - expenses,
    };
  }

  // -- Balance Sheet -----------------------------------------------------------

  /// Balance sheet up to [asOfDate].
  Future<Map<String, dynamic>> getBalanceSheet(
    int businessId, {
    String? asOfDate,
  }) async {
    final where = StringBuffer('''
      je.business_id = ?
      AND je.status = 'posted'
      AND coa.account_type IN ('Asset', 'Liability', 'Equity')
    ''');
    final args = <Object?>[businessId];
    if (asOfDate != null) {
      where.write(' AND je.entry_date <= ?');
      args.add(asOfDate);
    }
    final rows = _db.select('''
      SELECT
        coa.account_type,
        COALESCE(SUM(jl.debit - jl.credit), 0) AS amount
      FROM journal_lines jl
      JOIN journal_entries je ON je.id = jl.journal_entry_id
      JOIN chart_of_accounts coa ON coa.id = jl.account_id
      WHERE $where
      GROUP BY coa.account_type;
    ''', args);

    double assets = 0;
    double liabilities = 0;
    double equity = 0;
    for (final row in rows) {
      final amount = (row['amount'] as num?)?.toDouble() ?? 0;
      switch (row['account_type']) {
        case 'Asset':
          assets += amount;
        case 'Liability':
          liabilities += amount;
        case 'Equity':
          equity += amount;
      }
    }
    return {
      'assets': assets,
      'liabilities': liabilities,
      'equity': equity,
      'net_worth': assets - liabilities,
    };
  }
}
