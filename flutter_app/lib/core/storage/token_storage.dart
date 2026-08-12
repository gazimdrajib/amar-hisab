import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user.dart';

/// Persists the JWT plus the lightweight user profile between app launches.
class TokenStorage {
  static const _tokenKey = 'jwt_token';
  static const _userJsonKey = 'current_user_json';
  static const _permissionsKey = 'permissions_csv';

  Future<void> save({
    required String token,
    required User user,
    required List<String> permissions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userJsonKey, user.toRawJson());
    await prefs.setString(_permissionsKey, permissions.join(','));
  }

  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<User?> readUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userJsonKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return User.fromRawJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> readPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final csv = prefs.getString(_permissionsKey);
    if (csv == null || csv.isEmpty) return const [];
    return csv.split(',');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userJsonKey);
    await prefs.remove(_permissionsKey);
  }
}
