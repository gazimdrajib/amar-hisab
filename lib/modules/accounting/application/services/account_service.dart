import '../../../../core/services/audit_service.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

/// Error raised by [AccountService]; carries a machine-readable [code] the
/// controller maps to an HTTP status.
class AccountServiceException implements Exception {
  const AccountServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AccountServiceException($code): $message';
}

/// CRUD for the chart of accounts (Architecture Book §14.2).
class AccountService {
  AccountService(this._accountRepo, this._audit);

  final AccountRepository _accountRepo;
  final AuditService _audit;

  Future<Account> getAccount(int businessId, int id) async {
    final account = await _accountRepo.findById(id);
    if (account == null || account.businessId != businessId) {
      throw const AccountServiceException('not_found', 'Account not found');
    }
    return account;
  }

  Future<List<Account>> listAccounts(
    int businessId, {
    String? accountType,
    bool? activeOnly,
  }) =>
      _accountRepo.list(
        businessId,
        accountType: accountType,
        activeOnly: activeOnly,
      );

  Future<Account> createAccount({
    required int businessId,
    required String accountCode,
    required String accountName,
    required String accountType,
    int? parentId,
    required int actorId,
  }) async {
    final existing = await _accountRepo.findByCode(businessId, accountCode);
    if (existing != null) {
      throw const AccountServiceException(
          'duplicate_code', 'Account code already exists');
    }

    final account = await _accountRepo.insert(Account(
      accountCode: accountCode,
      accountName: accountName,
      accountType: accountType,
      parentId: parentId,
      businessId: businessId,
    ));

    _audit.logAction(
      userId: actorId,
      entityType: 'account',
      entityId: account.id!,
      action: 'create',
      newValue: 'code=$accountCode; name=$accountName; type=$accountType',
      businessId: businessId,
    );
    return account;
  }

  Future<Account> updateAccount({
    required int businessId,
    required int id,
    String? accountName,
    String? accountType,
    int? parentId,
    required int actorId,
  }) async {
    final existing = await getAccount(businessId, id);
    if (existing.isSystem) {
      throw const AccountServiceException(
          'system_account', 'System accounts cannot be modified');
    }

    final updated = await _accountRepo.update(existing.copyWith(
      accountName: accountName ?? existing.accountName,
      accountType: accountType ?? existing.accountType,
      parentId: parentId ?? existing.parentId,
    ));

    _audit.logAction(
      userId: actorId,
      entityType: 'account',
      entityId: id,
      action: 'update',
      oldValue:
          'name=${existing.accountName}; type=${existing.accountType}',
      newValue: 'name=${updated.accountName}; type=${updated.accountType}',
      businessId: businessId,
    );
    return updated;
  }

  Future<void> deleteAccount({
    required int businessId,
    required int id,
    required int actorId,
  }) async {
    final existing = await getAccount(businessId, id);
    if (existing.isSystem) {
      throw const AccountServiceException(
          'system_account', 'System accounts cannot be deleted');
    }

    await _accountRepo.softDelete(id);
    _audit.logAction(
      userId: actorId,
      entityType: 'account',
      entityId: id,
      action: 'delete',
      businessId: businessId,
    );
  }
}
