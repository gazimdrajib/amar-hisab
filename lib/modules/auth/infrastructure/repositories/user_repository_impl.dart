import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

/// SQLite implementation of [UserRepository].
///
/// Every query is parameterised (no string interpolation of user input) and
/// rows are mapped through [_fromRow] – the single mapper for the entity.
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._db);

  final Database _db;

  // -- Mapper ----------------------------------------------------------------

  User _fromRow(Map<String, Object?> row, {String? roleName}) {
    DateTime? parseDate(Object? v) =>
        v is String ? DateTime.tryParse(v) : null;
    return User(
      id: row['id'] as int?,
      businessId: row['business_id'] as int,
      username: row['username'] as String,
      passwordHash: row['password_hash'] as String,
      salt: row['salt'] as String,
      fullName: row['full_name'] as String,
      roleId: row['role_id'] as int,
      isActive: (row['is_active'] as int? ?? 1) == 1,
      createdAt: parseDate(row['created_at']),
      updatedAt: parseDate(row['updated_at']),
      roleName: roleName,
    );
  }

  // -- Queries ---------------------------------------------------------------

  @override
  Future<User?> findById(int id) async {
    final rows = _db.select(
      'SELECT u.*, r.name AS role_name FROM users u '
      'LEFT JOIN roles r ON r.id = u.role_id WHERE u.id = ?;',
      [id],
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first, roleName: rows.first['role_name'] as String?);
  }

  @override
  Future<User?> findByUsername(int businessId, String username) async {
    final rows = _db.select(
      'SELECT u.*, r.name AS role_name FROM users u '
      'LEFT JOIN roles r ON r.id = u.role_id '
      'WHERE u.business_id = ? AND u.username = ?;',
      [businessId, username],
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first, roleName: rows.first['role_name'] as String?);
  }

  @override
  Future<List<User>> findAllByBusiness(int businessId,
      {bool includeInactive = false}) async {
    final rows = _db.select(
      'SELECT u.*, r.name AS role_name FROM users u '
      'LEFT JOIN roles r ON r.id = u.role_id '
      'WHERE u.business_id = ? ${includeInactive ? '' : 'AND u.is_active = 1'} '
      'ORDER BY u.username ASC;',
      [businessId],
    );
    return rows
        .map((r) => _fromRow(r, roleName: r['role_name'] as String?))
        .toList();
  }

  // -- Mutations -------------------------------------------------------------

  @override
  Future<User> insert(User user) async {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO users '
      '(business_id, username, password_hash, salt, full_name, role_id, '
      ' is_active, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        user.businessId,
        user.username,
        user.passwordHash,
        user.salt,
        user.fullName,
        user.roleId,
        user.isActive ? 1 : 0,
        now,
        now,
      ],
    );
    final id = _db.lastInsertRowId;
    final created = await findById(id);
    return created!;
  }

  @override
  Future<User> update(User user) async {
    _db.execute(
      'UPDATE users SET username = ?, full_name = ?, role_id = ?, '
      'is_active = ?, updated_at = ? WHERE id = ?;',
      [
        user.username,
        user.fullName,
        user.roleId,
        user.isActive ? 1 : 0,
        DateTime.now().toUtc().toIso8601String(),
        user.id,
      ],
    );
    final fresh = await findById(user.id!);
    return fresh!;
  }

  @override
  Future<void> updatePassword(
      int userId, String salt, String passwordHash) async {
    _db.execute(
      'UPDATE users SET salt = ?, password_hash = ?, updated_at = ? '
      'WHERE id = ?;',
      [salt, passwordHash, DateTime.now().toUtc().toIso8601String(), userId],
    );
  }

  @override
  Future<void> deactivate(int userId) async {
    _db.execute(
      'UPDATE users SET is_active = 0, updated_at = ? WHERE id = ?;',
      [DateTime.now().toUtc().toIso8601String(), userId],
    );
  }

  // -- Role helpers ----------------------------------------------------------

  @override
  String? roleNameFor(int roleId) {
    final rows =
        _db.select('SELECT name FROM roles WHERE id = ?;', [roleId]);
    if (rows.isEmpty) return null;
    return rows.first['name'] as String;
  }

  @override
  int? ownerRoleId() => roleIdForName('Owner');

  @override
  int? roleIdForName(String name) {
    final rows =
        _db.select('SELECT id FROM roles WHERE name = ?;', [name]);
    if (rows.isEmpty) return null;
    return rows.first['id'] as int;
  }
}
