import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

/// Chart of accounts entry (Database Book §3.5 – `chart_of_accounts`).
@freezed
class Account with _$Account {
  const factory Account({
    int? id,
    required String accountCode,
    required String accountName,
    required String accountType, // Asset, Liability, Equity, Revenue, Expense
    int? parentId,
    @Default(true) bool isActive,
    @Default(false) bool isSystem,
    required int businessId,
    DateTime? createdAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}
