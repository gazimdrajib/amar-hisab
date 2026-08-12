import 'package:crypto/crypto.dart';

/// HMAC signature utilities used for portal token validation and device
/// authentication proofs. Shared by [PortalService] (teacher-generated QR
/// tokens) and the sync layer (device proof against the Cloud Sync Service).
///
/// Secrets always come from environment variables – nothing is hard-coded.
class HmacHelper {
  HmacHelper._();

  /// Hex-encoded HMAC-SHA256 of [message] under [secret].
  static String hmacSha256(String secret, String message) {
    final digest = Hmac(sha256, secret.codeUnits);
    return digest.convert(message.codeUnits).toString();
  }

  /// SHA-256 hex digest of [payload] (used to store token hashes).
  static String sha256Hex(String payload) =>
      sha256.convert(payload.codeUnits).toString();

  /// Constant-time comparison to avoid timing attacks on token checks.
  static bool secureEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
