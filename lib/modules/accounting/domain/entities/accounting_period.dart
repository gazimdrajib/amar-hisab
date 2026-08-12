import 'package:freezed_annotation/freezed_annotation.dart';

part 'accounting_period.freezed.dart';
part 'accounting_period.g.dart';

/// Fiscal accounting period (Database Book §3.5 – `accounting_periods`).
@freezed
class AccountingPeriod with _$AccountingPeriod {
  const factory AccountingPeriod({
    int? id,
    required DateTime startDate,
    required DateTime endDate,
    @Default(false) bool isClosed,
    required int businessId,
  }) = _AccountingPeriod;

  factory AccountingPeriod.fromJson(Map<String, dynamic> json) =>
      _$AccountingPeriodFromJson(json);
}
