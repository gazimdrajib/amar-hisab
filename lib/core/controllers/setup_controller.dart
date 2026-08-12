import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import '../middleware/rbac_middleware.dart';
import '../seeders/role_seeder.dart';
import '../services/audit_service.dart';
import '../utils/jwt_helper.dart';
import '../utils/password_hasher.dart';
import '../utils/response_envelope.dart';

/// One-time setup endpoint: `/setup/*`.
///
/// * `GET  /setup/status`     Ã¢â‚¬â€œ returns whether initialisation is complete.
/// * `POST /setup/initialize` Ã¢â‚¬â€œ creates the first business + Owner user and
///   seeds roles/permissions, returning a JWT for the Owner. This endpoint
///   only runs once; subsequent calls return 409.
class SetupController {
  SetupController(
    this._db,
    this._roleSeeder,
    this._audit,
    this._permissionChecker,
  );

  final Database _db;
  final RoleSeeder _roleSeeder;
  final AuditService _audit;
  final PermissionChecker _permissionChecker;

  Router get router {
    final r = Router();
    r.get('/status', _status);
    r.post('/initialize', _initialize);
    return r;
  }

  Future<Response> _status(Request request) async {
    final rows = _db.select('SELECT id FROM businesses LIMIT 1;');
    return ResponseEnvelope.success({
      'initialized': rows.isNotEmpty,
      'version': '1.0.0',
    });
  }

  Future<Response> _initialize(Request request) async {
    // Guard: only allow first-time setup.
    final existing = _db.select('SELECT id FROM businesses LIMIT 1;');
    if (existing.isNotEmpty) {
      return ResponseEnvelope.conflict(
          'Setup has already been completed');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return ResponseEnvelope.badRequest('Invalid JSON body');
    }

    final businessName = body['businessName'] as String?;
    final businessType = (body['businessType'] as String?) ?? 'retail';
    final currency = (body['currency'] as String?) ?? 'BDT';
    final taxDefault = (body['taxDefault'] as num?)?.toDouble() ?? 0;
    final username = body['ownerUsername'] as String?;
    final password = body['ownerPassword'] as String?;
    final fullName = body['ownerFullName'] as String?;

    if (businessName == null || businessName.isEmpty) {
      return ResponseEnvelope.badRequest('businessName is required');
    }
    if (username == null || password == null || fullName == null) {
      return ResponseEnvelope.badRequest(
          'ownerUsername, ownerPassword and ownerFullName are required');
    }
    if (password.length < 8) {
      return ResponseEnvelope.badRequest(
          'Owner password must be at least 8 characters');
    }

    late int businessId;
    late int ownerId;

    _db.execute('BEGIN IMMEDIATE;');
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      // 1. Business
      _db.execute(
        'INSERT INTO businesses '
        '(name, type, address, phone, email, currency, tax_default, is_active, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?);',
        [
          businessName,
          businessType,
          body['address'] as String?,
          body['phone'] as String?,
          body['email'] as String?,
          currency,
          taxDefault,
          now,
          now,
        ],
      );
      businessId = _db.lastInsertRowId;

      // 2. Roles + permissions
      final roleIds = _roleSeeder.seed();
      final ownerRoleId = roleIds['Owner']!;

      // 3. Owner user
      final hashed = PasswordHasher.hash(password);
      _db.execute(
        'INSERT INTO users '
        '(business_id, username, password_hash, salt, full_name, role_id, is_active, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?);',
        [
          businessId,
          username,
          hashed.hash,
          hashed.salt,
          fullName,
          ownerRoleId,
          now,
          now,
        ],
      );
      ownerId = _db.lastInsertRowId;

      // 4. Default settings
      _db.execute(
        'INSERT INTO settings (business_id, key, value) VALUES (?, ?, ?);',
        [businessId, 'setup_completed', 'true'],
      );

      _audit.logAction(
        userId: ownerId,
        entityType: 'business',
        entityId: businessId,
        action: 'initialize',
        newValue: 'name=$businessName; owner=$username',
        businessId: businessId,
      );

      _db.execute('COMMIT;');
    } catch (e) {
      _db.execute('ROLLBACK;');
      return ResponseEnvelope.internalError('Setup failed: $e');
    }

    // 5. Invalidate RBAC cache and issue a JWT.
    _permissionChecker.invalidate();
    final token = JwtHelper.sign(
      userId: ownerId,
      roleId: _roleSeeder.roleIdFor('Owner')!,
      businessId: businessId,
      extra: {'username': username},
    );

    return ResponseEnvelope.created({
      'token': token,
      'businessId': businessId,
      'ownerUserId': ownerId,
      'permissions': _permissionChecker
          .permissionsForRole(_roleSeeder.roleIdFor('Owner')!)
          .toList(),
    }, message: 'Setup completed');
  }
}
