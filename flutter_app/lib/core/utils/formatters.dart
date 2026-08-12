import 'package:intl/intl.dart';

import '../constants/app_config.dart';

/// Currency + date formatting helpers.
class Fmt {
  Fmt._();

  static String money(double value) {
    final fmt = NumberFormat('#,##0.##');
    return '${AppSettingsHolder.currency}${fmt.format(value)}';
  }

  static String compactMoney(double value) {
    final fmt = NumberFormat.compact();
    return '${AppSettingsHolder.currency}${fmt.format(value)}';
  }

  static final _date = DateFormat('dd MMM yyyy');
  static final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  static String date(DateTime? d) => d == null ? '—' : _date.format(d.toLocal());
  static String dateTime(DateTime? d) =>
      d == null ? '—' : _dateTime.format(d.toLocal());
  static String qty(double value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
}

/// Mutable holder so formatters don't need a WidgetRef
/// (kept in sync by the settings provider).
class AppSettingsHolder {
  AppSettingsHolder._();
  static String currency = '৳';
  static String baseUrl = AppConfig.defaultBaseUrl;
  static int? defaultWarehouseId;
}
