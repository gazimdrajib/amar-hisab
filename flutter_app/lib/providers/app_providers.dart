import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_config.dart';
import '../core/network/api_client.dart';
import '../core/utils/formatters.dart';

/// Global API client. Rebuilt when settings change so the base URL stays in sync.
final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(
          appSettingsProvider.select((s) => s.value?.baseUrl)) ??
      AppConfig.defaultBaseUrl;
  final client = ApiClient(baseUrl: baseUrl);
  client.onUnauthorized =
      () => ref.read(authInvalidCallbackProvider.notifier).state++;
  ref.onDispose(client.close);
  return client;
});

/// Used to notify listeners (auth) when the API returns 401.
final authInvalidCallbackProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------

class AppSettings {
  final String baseUrl;
  final String currency;
  final int? defaultWarehouseId;

  const AppSettings({
    required this.baseUrl,
    required this.currency,
    this.defaultWarehouseId,
  });

  AppSettings copyWith({String? baseUrl, String? currency, int? warehouseId}) =>
      AppSettings(
        baseUrl: baseUrl ?? this.baseUrl,
        currency: currency ?? this.currency,
        defaultWarehouseId: warehouseId ?? defaultWarehouseId,
      );
}

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings(
      baseUrl: prefs.getString(AppConfig.keyBaseUrl) ?? AppConfig.defaultBaseUrl,
      currency: prefs.getString(AppConfig.keyCurrency) ?? '৳',
      defaultWarehouseId: prefs.getInt(AppConfig.keyWarehouseId),
    );
    _sync(settings);
    return settings;
  }

  void _sync(AppSettings s) {
    AppSettingsHolder.baseUrl = s.baseUrl;
    AppSettingsHolder.currency = s.currency;
    AppSettingsHolder.defaultWarehouseId = s.defaultWarehouseId;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.keyBaseUrl, url);
    final next = (state.value ?? AppSettings(
        baseUrl: url, currency: '৳')).copyWith(baseUrl: url);
    _sync(next);
    state = AsyncData(next);
  }

  Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.keyCurrency, currency);
    final next = state.value!.copyWith(currency: currency);
    _sync(next);
    state = AsyncData(next);
  }

  Future<void> setDefaultWarehouse(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConfig.keyWarehouseId, id);
    final next = state.value!.copyWith(warehouseId: id);
    _sync(next);
    state = AsyncData(next);
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);
