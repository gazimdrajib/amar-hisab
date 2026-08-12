import '../entities/account.dart';

abstract class AccountRepository {
  Future<Account> insert(Account account);
  Future<Account?> findById(int id);
  Future<Account?> findByCode(int businessId, String accountCode);
  Future<Account?> findByName(int businessId, String accountName);
  Future<List<Account>> list(
    int businessId, {
    String? accountType,
    bool? activeOnly,
  });
  Future<Account> update(Account account);
  Future<void> softDelete(int id);
}
