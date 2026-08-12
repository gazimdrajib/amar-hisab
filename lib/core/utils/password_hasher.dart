import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 password hasher.
///
/// Each password is hashed with a per-user random salt, which is stored
/// alongside the hash (`salt:hash`). No secret is stored in code. Use
/// [hash] when creating a user and [verify] when authenticating.
class PasswordHasher {
  PasswordHasher._();

  static final Random _rng = Random.secure();

  /// Generate a new cryptographically-random URL-safe salt (32 bytes).
  static String generateSalt() {
    final bytes = List<int>.generate(32, (_) => _rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Produce `sha256(salt + password)` as a lowercase hex digest.
  static String hashPassword(String password, String salt) {
    final digest = sha256.convert(utf8.encode('$salt$password'));
    return digest.toString();
  }

  /// Convenience: returns `{'salt': ..., 'hash': ...}` for a new password.
  static ({String salt, String hash}) hash(String password) {
    final salt = generateSalt();
    return (salt: salt, hash: hashPassword(password, salt));
  }

  /// Constant-time-ish comparison of a pending password with a stored salt
  /// and hash.
  static bool verify(String password, String salt, String expectedHash) {
    final actual = hashPassword(password, salt);
    if (actual.length != expectedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return diff == 0;
  }
}
