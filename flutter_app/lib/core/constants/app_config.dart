/// Application-wide configuration for Amar Hisab POS.
class AppConfig {
  AppConfig._();

  /// Base URL of the Dart Shelf backend.
  /// Default assumes the Shelf server runs on the same machine / emulator host.
  /// Android emulator: use http://10.0.2.2:8080
  static const String defaultBaseUrl = 'http://localhost:8080';

  /// API version prefix mounted in bin/server.dart.
  static const String apiPrefix = '/api/v1';

  /// SharedPreferences keys.
  static const String keyBaseUrl = 'server_base_url';
  static const String keyCurrency = 'currency_symbol';
  static const String keyWarehouseId = 'default_warehouse_id';

  static const String dbName = 'amar_hisab_cache.db';
  static const int dbVersion = 1;
}
