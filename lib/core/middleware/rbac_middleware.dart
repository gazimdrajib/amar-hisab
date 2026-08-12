import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

import '../utils/response_envelope.dart';
import 'auth_middleware.dart';

/// Permission checker with an in-memory, per-role cache.
///
/// Loads `(resource, action)` tuples from the `permissions` table once per
/// role and caches them until [invalidate] is called (e.g. after a role or
/// permission change). All SQL uses parameterised queries.
class PermissionChecker {
  PermissionChecker(this._db);

  final Database _db;

  final Map<int, Set<String>> _cache = {};

  /// True when [roleId] holds the `resource:action` permission.
  bool hasPermission(int roleId, String resource, String action) {
    final permissions = _cache.putIfAbsent(roleId, () => _load(roleId));
    return permissions.contains('$resource:$action');
  }

  Set<String> _load(int roleId) {
    final rows = _db.select(
      'SELECT resource, action FROM permissions '
      'WHERE role_id = ? AND EXISTS (SELECT 1 FROM roles WHERE id = ? AND is_active = 1);',
      [roleId, roleId],
    );
    return {for (final r in rows) '${r['resource']}:${r['action']}'};
  }

  /// Drop cached permissions for one role, or for all roles when
  /// [roleId] is null. Call after any role/permission mutation.
  void invalidate([int? roleId]) {
    if (roleId == null) {
      _cache.clear();
    } else {
      _cache.remove(roleId);
    }
  }

  /// Full permission list for a role (used by `GET /auth/me`).
  Set<String> permissionsForRole(int roleId) =>
      Set.unmodifiable(_cache.putIfAbsent(roleId, () => _load(roleId)));
}

/// Route-level RBAC enforcement.
///
/// Wrap an individual route handler:
/// ```dart
/// router.post('/products',
///     requirePermission(checker, 'product', 'create')(_createHandler));
/// ```
/// Reads the [AuthContext] injected by [authMiddleware] and returns a 403
/// envelope when the user's role lacks `resource:action`.
Middleware requirePermission(
  PermissionChecker checker,
  String resource,
  String action,
) {
  return (Handler innerHandler) {
    return (Request request) async {
      final auth = authContextOf(request);
      if (auth == null) {
        return ResponseEnvelope.unauthorized();
      }
      if (!checker.hasPermission(auth.roleId, resource, action)) {
        return ResponseEnvelope.forbidden(
          'Missing permission: $resource:$action',
        );
      }
      return innerHandler(request);
    };
  };
}
