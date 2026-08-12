import 'dart:convert';

/// Mirrors the backend `User.toSafeJson()` payload.
class User {
  final int id;
  final int businessId;
  final String username;
  final String fullName;
  final int roleId;
  final String? roleName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.businessId,
    required this.username,
    required this.fullName,
    required this.roleId,
    this.roleName,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] as num).toInt(),
        businessId: (json['businessId'] as num).toInt(),
        username: json['username']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        roleId: (json['roleId'] as num?)?.toInt() ?? 0,
        roleName: json['roleName']?.toString(),
        isActive: json['isActive'] == true || json['isActive'] == 1,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'username': username,
        'fullName': fullName,
        'roleId': roleId,
        'roleName': roleName,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  String toRawJson() => jsonEncode(toJson());

  factory User.fromRawJson(String raw) =>
      User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// Payload returned by POST /api/v1/auth/login.
class AuthSession {
  final String token;
  final User user;
  final List<String> permissions;

  const AuthSession({
    required this.token,
    required this.user,
    required this.permissions,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        token: json['token']?.toString() ?? '',
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        permissions: (json['permissions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  bool can(String permission) => permissions.contains(permission);
}
