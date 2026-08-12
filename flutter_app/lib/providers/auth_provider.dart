import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/token_storage.dart';
import '../models/user.dart';
import 'app_providers.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Server reachability + setup status (GET /setup/status, public).
final setupStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final data = await client.get('/setup/status', authenticated: false);
    return {
      'reachable': true,
      'initialized': data?['initialized'] == true,
    };
  } on ApiException {
    return {'reachable': true, 'initialized': true};
  } catch (_) {
    return {'reachable': false, 'initialized': false};
  }
});

class AuthState {
  final AuthSession? session;
  final bool isLoading;
  final String? error;

  /// True until [AuthNotifier.restore] finishes reading persisted session.
  final bool restoring;

  const AuthState({
    this.session,
    this.isLoading = false,
    this.error,
    this.restoring = true,
  });

  bool get isAuthenticated => session != null;

  bool can(String permission) => session?.can(permission) ?? false;

  AuthState copyWith({
    AuthSession? session,
    bool? isLoading,
    String? error,
    bool? restoring,
    bool clearSession = false,
    bool clearError = false,
  }) =>
      AuthState(
        session: clearSession ? null : (session ?? this.session),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        restoring: restoring ?? this.restoring,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Force-logout when any API call gets a 401.
    ref.listen(authInvalidCallbackProvider, (prev, next) {
      if (prev != next) logout();
    });
    Future.microtask(restore);
    return const AuthState();
  }

  ApiClient get _api => ref.read(apiClientProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);

  Future<void> restore() async {
    try {
      final token = await _storage.readToken();
      final user = await _storage.readUser();
      final permissions = await _storage.readPermissions();
      if (token != null && user != null) {
        _api.setToken(token);
        state = AuthState(
          session: AuthSession(token: token, user: user, permissions: permissions),
          restoring: false,
        );
        // Refresh profile in the background (silently).
        try {
          final data = await _api.get(ApiEndpoints.me);
          final freshUser = User.fromJson(data['user'] as Map<String, dynamic>);
          final freshPerms = (data['permissions'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              permissions;
          state = state.copyWith(
            session: AuthSession(token: token, user: freshUser, permissions: freshPerms),
          );
          await _storage.save(token: token, user: freshUser, permissions: freshPerms);
        } catch (_) {/* keep cached session */}
      } else {
        state = const AuthState(restoring: false);
      }
    } catch (_) {
      state = const AuthState(restoring: false);
    }
  }

  Future<bool> login(String username, String password, {int businessId = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true, restoring: false);
    try {
      final data = await _api.post(
        ApiEndpoints.login,
        body: {'username': username, 'password': password, 'businessId': businessId},
        authenticated: false,
      );
      final session = AuthSession.fromJson(
          jsonDecode(jsonEncode(data)) as Map<String, dynamic>);
      _api.setToken(session.token);
      await _storage.save(
          token: session.token, user: session.user, permissions: session.permissions);
      state = AuthState(session: session, restoring: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message, restoring: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), restoring: false);
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    _api.setToken(null);
    state = const AuthState(restoring: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
