import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Signed JWT payload returned after [JwtHelper.verify] succeeds.
class JwtPayload {
  JwtPayload({
    required this.userId,
    required this.roleId,
    required this.businessId,
    required this.expiresAt,
    this.extra = const {},
  });

  final int userId;
  final int roleId;
  final int businessId;
  final DateTime expiresAt;
  final Map<String, dynamic> extra;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() => {
        'sub': userId,
        'uid': userId,
        'roleId': roleId,
        'businessId': businessId,
        'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
        ...extra,
      };
}

/// HMAC-SHA256 JWT helper.
///
/// The signing secret is read from the `JWT_SECRET` environment variable;
/// it is never hard-coded. Tokens follow the standard `header.payload.sig`
/// Base64-URL layout.
class JwtHelper {
  JwtHelper._();

  static String? _overrideSecret;

  /// Inject the signing secret (e.g. from the dotenv map) at server startup.
  /// Falls back to the `JWT_SECRET` environment variable when not set.
  static void initSecret(String secret) => _overrideSecret = secret;

  static String get _secret {
    final s = _overrideSecret ?? Platform.environment['JWT_SECRET'] ?? '';
    if (s.isEmpty) {
      throw StateError(
        'JWT_SECRET environment variable is not set. '
        'Create a .env file (see .env.example) and provide a strong secret.',
      );
    }
    return s;
  }

  static const Map<String, dynamic> _header = {'alg': 'HS256', 'typ': 'JWT'};

  /// Create a signed JWT for the given identity with the provided lifetime.
  static String sign({
    required int userId,
    required int roleId,
    required int businessId,
    Duration lifetime = const Duration(hours: 8),
    Map<String, dynamic> extra = const {},
  }) {
    final payload = JwtPayload(
      userId: userId,
      roleId: roleId,
      businessId: businessId,
      expiresAt: DateTime.now().toUtc().add(lifetime),
      extra: extra,
    ).toMap();

    final h = _b64Url(utf8.encode(jsonEncode(_header)));
    final p = _b64Url(utf8.encode(jsonEncode(payload)));
    final signature = _signPart('$h.$p');
    return '$h.$p.$signature';
  }

  /// Verify [token]. Returns a [JwtPayload] when the signature matches and
  /// the token is unexpired; returns `null` otherwise (never throws for bad
  /// input).
  static JwtPayload? verify(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final expectedSig = _signPart('${parts[0]}.${parts[1]}');
      if (expectedSig != parts[2]) return null;

      final payloadJson = jsonDecode(utf8.decode(_b64UrlDecode(parts[1])))
          as Map<String, dynamic>;

      final expSeconds = payloadJson['exp'] as int?;
      if (expSeconds == null) return null;
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000, isUtc: true);
      if (DateTime.now().toUtc().isAfter(expiresAt)) return null;

      final extra = Map<String, dynamic>.from(payloadJson)
        ..removeWhere((k, _) =>
            k == 'sub' || k == 'uid' || k == 'roleId' || k == 'businessId' || k == 'exp');

      return JwtPayload(
        userId: (payloadJson['uid'] ?? payloadJson['sub']) as int,
        roleId: payloadJson['roleId'] as int,
        businessId: payloadJson['businessId'] as int,
        expiresAt: expiresAt,
        extra: extra,
      );
    } catch (_) {
      return null;
    }
  }

  static String _signPart(String data) {
    final hmac = Hmac(sha256, utf8.encode(_secret));
    return _b64Url(hmac.convert(utf8.encode(data)).bytes);
  }

  static String _b64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static List<int> _b64UrlDecode(String input) {
    var s = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (s.length % 4) {
      case 2:
        s += '==';
        break;
      case 3:
        s += '=';
        break;
    }
    return base64.decode(s);
  }
}
