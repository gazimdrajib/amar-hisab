import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// System user entity. Sensitive fields (`passwordHash`, `salt`) are kept on
/// the entity for repository round-trips but are stripped before any JSON
/// response via [User.toSafeJson].
@freezed
class User with _$User {
  const User._();

  const factory User({
    int? id,
    required int businessId,
    required String username,
    required String passwordHash,
    required String salt,
    required String fullName,
    required int roleId,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    /// Optional role name resolved via join (authorization responses only).
    String? roleName,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// JSON view that never leaks credentials.
  Map<String, dynamic> toSafeJson() => {
        'id': id,
        'businessId': businessId,
        'username': username,
        'fullName': fullName,
        'roleId': roleId,
        if (roleName != null) 'roleName': roleName,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
