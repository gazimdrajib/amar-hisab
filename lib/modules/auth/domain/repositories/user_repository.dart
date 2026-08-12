import '../entities/user.dart';

/// Contract for user persistence.
abstract class UserRepository {
  Future<User?> findById(int id);

  Future<User?> findByUsername(int businessId, String username);

  /// Only active users by default; pass [includeInactive] for admin lists.
  Future<List<User>> findAllByBusiness(int businessId,
      {bool includeInactive = false});

  /// Insert a new user, returning the persisted entity (with id).
  Future<User> insert(User user);

  /// Update profile/role/active flag. Credentials go through
  /// [updatePassword].
  Future<User> update(User user);

  /// Replace the stored salt/hash for [userId].
  Future<void> updatePassword(int userId, String salt, String passwordHash);

  /// Soft delete: sets `is_active = 0`.
  Future<void> deactivate(int userId);

  /// Role helpers -----------------------------------------------------------

  String? roleNameFor(int roleId);

  int? ownerRoleId();

  int? roleIdForName(String name);
}
