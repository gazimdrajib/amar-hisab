import '../../../../core/services/audit_service.dart';
import '../../../../core/utils/password_hasher.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

/// Business rule violations raised by the user service.
class UserServiceException implements Exception {
  UserServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

/// CRUD for users with audit logging and the RBAC rule:
/// **Admins (and any non-Owner) may not assign the Owner role.**
class UserService {
  UserService(this._users, this._audit);

  final UserRepository _users;
  final AuditService _audit;

  Future<List<User>> list(int businessId, {bool includeInactive = false}) =>
      _users.findAllByBusiness(businessId, includeInactive: includeInactive);

  Future<User?> getById(int id) => _users.findById(id);

  /// Create a new user.
  ///
  /// Throws [UserServiceException] when the username is taken or when a
  /// non-Owner actor tries to grant the Owner role.
  Future<User> create({
    required int businessId,
    required String username,
    required String password,
    required String fullName,
    required int roleId,
    required int actorId,
    required String actorRoleName,
  }) async {
    _assertRoleAllowed(roleId, actorRoleName);

    final existing = await _users.findByUsername(businessId, username);
    if (existing != null) {
      throw UserServiceException('username_taken', 'Username already exists');
    }

    final hashed = PasswordHasher.hash(password);
    final user = User(
      businessId: businessId,
      username: username,
      passwordHash: hashed.hash,
      salt: hashed.salt,
      fullName: fullName,
      roleId: roleId,
      isActive: true,
    );
    final created = await _users.insert(user);

    _audit.logAction(
      userId: actorId,
      entityType: 'user',
      entityId: created.id!,
      action: 'create',
      newValue:
          'username=${created.username}; role=$roleId; name=${created.fullName}',
      businessId: businessId,
    );
    return created;
  }

  /// Update profile, role, and/or active flag (no password change here).
  Future<User> update({
    required int id,
    String? username,
    String? fullName,
    int? roleId,
    bool? isActive,
    required int actorId,
    required String actorRoleName,
    required int actorBusinessId,
  }) async {
    final existing = await _users.findById(id);
    if (existing == null) {
      throw UserServiceException('not_found', 'User not found');
    }
    if (existing.businessId != actorBusinessId) {
      throw UserServiceException(
          'cross_business', 'Cannot modify users in another business');
    }
    if (roleId != null) {
      _assertRoleAllowed(roleId, actorRoleName);
    }
    // Never allow demoting/deactivating the primary Owner account
    // (RBAC Book §3.1: "The Owner account ... cannot be deleted or demoted").
    final ownerId = _users.ownerRoleId();
    final isOwnerTarget = ownerId != null && existing.roleId == ownerId;
    if (isOwnerTarget &&
        actorRoleName != 'Owner' &&
        ((roleId != null && roleId != ownerId) || isActive == false)) {
      throw UserServiceException(
          'owner_protected', 'The Owner account cannot be demoted or deactivated');
    }

    final updated = await _users.update(existing.copyWith(
      username: username ?? existing.username,
      fullName: fullName ?? existing.fullName,
      roleId: roleId ?? existing.roleId,
      isActive: isActive ?? existing.isActive,
    ));

    final changes = <String>[
      if (username != null && username != existing.username)
        'username: ${existing.username} -> $username',
      if (fullName != null && fullName != existing.fullName)
        'fullName: ${existing.fullName} -> $fullName',
      if (roleId != null && roleId != existing.roleId)
        'roleId: ${existing.roleId} -> $roleId',
      if (isActive != null && isActive != existing.isActive)
        'isActive: ${existing.isActive} -> $isActive',
    ];
    if (changes.isNotEmpty) {
      _audit.logAction(
        userId: actorId,
        entityType: 'user',
        entityId: id,
        action: 'update',
        newValue: changes.join('; '),
        businessId: actorBusinessId,
      );
    }
    return updated;
  }

  /// Change a user's password (requires `user:update`; own password may be
  /// changed by the user themselves).
  Future<void> changePassword({
    required int id,
    required String newPassword,
    required int actorId,
    required int actorBusinessId,
  }) async {
    final existing = await _users.findById(id);
    if (existing == null) {
      throw UserServiceException('not_found', 'User not found');
    }
    if (existing.businessId != actorBusinessId) {
      throw UserServiceException(
          'cross_business', 'Cannot modify users in another business');
    }
    if (newPassword.length < 8) {
      throw UserServiceException(
          'weak_password', 'Password must be at least 8 characters');
    }

    final hashed = PasswordHasher.hash(newPassword);
    await _users.updatePassword(id, hashed.salt, hashed.hash);

    _audit.logAction(
      userId: actorId,
      entityType: 'user',
      entityId: id,
      action: 'update',
      fieldName: 'password',
      newValue: 'changed',
      businessId: actorBusinessId,
    );
  }

  /// Soft-delete: deactivate.
  Future<void> delete({
    required int id,
    required int actorId,
    required String actorRoleName,
    required int actorBusinessId,
  }) async {
    if (id == actorId) {
      throw UserServiceException(
          'self_delete', 'You cannot deactivate your own account');
    }
    final existing = await _users.findById(id);
    if (existing == null) {
      throw UserServiceException('not_found', 'User not found');
    }
    if (existing.businessId != actorBusinessId) {
      throw UserServiceException(
          'cross_business', 'Cannot delete users in another business');
    }
    final ownerId = _users.ownerRoleId();
    if (ownerId != null && existing.roleId == ownerId) {
      throw UserServiceException(
          'owner_protected', 'The Owner account cannot be deleted');
    }

    await _users.deactivate(id);

    _audit.logAction(
      userId: actorId,
      entityType: 'user',
      entityId: id,
      action: 'delete',
      businessId: actorBusinessId,
    );
  }

  // -------------------------------------------------------------------------

  void _assertRoleAllowed(int roleId, String actorRoleName) {
    final ownerId = _users.ownerRoleId();
    if (ownerId != null && roleId == ownerId && actorRoleName != 'Owner') {
      throw UserServiceException(
        'forbidden_role_assignment',
        'Only an Owner may assign the Owner role',
      );
    }
    final roleName = _users.roleNameFor(roleId);
    if (roleName == null) {
      throw UserServiceException('role_not_found', 'Role does not exist');
    }
  }
}
