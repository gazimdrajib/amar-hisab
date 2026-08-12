import '../../../../core/utils/jwt_helper.dart';
import '../../../../core/utils/password_hasher.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

/// Result of a successful login attempt.
class LoginResult {
  const LoginResult({required this.user, required this.token});

  final User user;
  final String token;
}

/// Authentication & token issuance.
class AuthService {
  AuthService(this._users);

  final UserRepository _users;

  /// Attempt a username + password login inside [businessId].
  ///
  /// Returns null on bad credentials or when the user is deactivated. On
  /// success returns the user and a signed JWT (8-hour lifetime, per RBAC
  /// Book §7).
  Future<LoginResult?> login({
    required int businessId,
    required String username,
    required String password,
  }) async {
    final user = await _users.findByUsername(businessId, username);
    if (user == null || !user.isActive) return null;

    final ok = PasswordHasher.verify(password, user.salt, user.passwordHash);
    if (!ok) return null;

    final token = JwtHelper.sign(
      userId: user.id!,
      roleId: user.roleId,
      businessId: user.businessId,
      extra: {'username': user.username},
    );
    return LoginResult(user: user, token: token);
  }

  /// Resolve the currently-authenticated user from a token's user id.
  Future<User?> me(int userId) => _users.findById(userId);
}
