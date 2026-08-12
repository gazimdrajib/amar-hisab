import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

/// SQLite implementation of [AccountRepository]. Parameterised queries only;
/// the caller (AccountService) owns the surrounding transaction.
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._db);

  final Database _db;

  // -- Mapper ---------------------------------------------------------------
  Account _fromRow(Map<String, Object?> r) {
    return Account(
      id: r['id'] as int?,
      accountCode: r['account_code'] as String,
      accountName: r['account_name'] as String,
      accountType: r['account_type'] as String,
      parentId: r['parent_id'] as int?,
      isActive: (r['is_active'] as int?) == 1,
      isSystem: (r['is_system'] as int?) == 1,
      businessId: r['business_id'] as int,
      createdAt: r['created_at'] is String
          ? DateTime.tryParse(r['created_at'] as String)
          : null,
    );
  }

  @override
  Future<Account> insert(Account account) async {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO chart_of_accounts '
      '(account_code, account_name, account_type, parent_id, is_active, '
      ' is_system, business_id, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?);',
      [
        account.accountCode,
        account.accountName,
        account.accountType,
        account.parentId,
        account.isActive ? 1 : 0,
        account.isSystem ? 1 : 0,
        account.businessId,
        now,
      ],
    );
    return account.copyWith(id: _db.lastInsertRowId);
  }

  @override
  Future<Account?> findById(int id) async {
    final rows =
        _db.select('SELECT * FROM chart_of_accounts WHERE id = ?;', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Account?> findByCode(int businessId, String accountCode) async {
    final rows = _db.select(
      'SELECT * FROM chart_of_accounts '
      'WHERE business_id = ? AND account_code = ?;',
      [businessId, accountCode],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Account?> findByName(int businessId, String accountName) async {
    final rows = _db.select(
      'SELECT * FROM chart_of_accounts '
      'WHERE business_id = ? AND account_name = ? AND is_active = 1;',
      [businessId, accountName],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<List<Account>> list(
    int businessId, {
    String? accountType,
    bool? activeOnly,
  }) async {
    final where = StringBuffer('business_id = ?');
    final args = <Object?>[businessId];
    if (accountType != null) {
      where.write(' AND account_type = ?');
      args.add(accountType);
    }
    if (activeOnly == true) {
      where.write(' AND is_active = 1');
    }
    final rows = _db.select(
      'SELECT * FROM chart_of_accounts WHERE $where ORDER BY account_code;',
      args,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Account> update(Account account) async {
    _db.execute(
      'UPDATE chart_of_accounts SET account_name = ?, account_type = ?, '
      'parent_id = ?, is_active = ? WHERE id = ?;',
      [
        account.accountName,
        account.accountType,
        account.parentId,
        account.isActive ? 1 : 0,
        account.id,
      ],
    );
    return (await findById(account.id!))!;
  }

  @override
  Future<void> softDelete(int id) async {
    _db.execute(
      'UPDATE chart_of_accounts SET is_active = 0 WHERE id = ?;',
      [id],
    );
  }
}
