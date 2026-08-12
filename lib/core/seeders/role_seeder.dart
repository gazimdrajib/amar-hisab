import 'package:sqlite3/sqlite3.dart';

/// Idempotent seeder for the six system roles and their permissions.
///
/// Permission assignments follow **RBAC Book – Section 4 (Permission
/// Matrix)**, including the Phase 8 Reports module matrix in §4.6
/// (Owner/Admin/Accountant/Manager receive `report:*` grants exactly as the
/// table specifies). Running [seed] multiple times is safe: roles are
/// matched by name and permission rows are guarded by `INSERT OR IGNORE`
/// against the `UNIQUE (role_id, resource, action)` constraint.
class RoleSeeder {
  RoleSeeder(this._db);

  final Database _db;

  /// The six system roles (RBAC Book §3).
  static const Map<String, String> systemRoles = {
    'Owner': 'Full, unrestricted access to every resource and action.',
    'Admin': 'Day-to-day operations; no business-type or Owner control.',
    'Manager': 'Sales/inventory oversight; no user management or financial reports.',
    'Cashier': 'POS sales, payments and own-history only.',
    'Accountant': 'Full financial data access; no operational transactions.',
    'Inventory Manager': 'Products, batches, transfers, adjustments and inventory reports.',
  };

  /// Permission matrix from RBAC Book §4 (sub-sections 4.1 – 4.7 +
  /// category/brand/unit & warehouse entries that accompany Products and
  /// Inventory modules).
  ///
  /// `Owner` is not listed exhaustively below on purpose – Owner receives
  /// every known permission via [allPermissions] in [seed].
  static const Map<String, Set<String>> rolePermissions = {
    'Admin': {
      // 4.1 Sales & Payments
      'sale:create', 'sale:read', 'sale:update', 'sale:delete', 'sale:return',
      'sale:approve_discount', 'payment:create', 'payment:read',
      'quotation:create', 'quotation:read',
      // 4.2 Purchase & Suppliers
      'purchase:create', 'purchase:read', 'purchase:update', 'purchase:delete',
      'purchase:return', 'purchase_order:create', 'supplier:create',
      'supplier:read', 'supplier:update', 'supplier_payment:create',
      // 4.3 Products & Inventory
      'product:create', 'product:read', 'product:update', 'product:delete',
      'category:create', 'category:read', 'category:update', 'category:delete',
      'brand:create', 'brand:read', 'brand:update', 'brand:delete',
      'unit:create', 'unit:read', 'unit:update', 'unit:delete',
      'warehouse:create', 'warehouse:read', 'warehouse:update', 'warehouse:delete',
      'batch:read', 'batch:update',
      'inventory:read', 'inventory:transfer', 'inventory:adjust', 'inventory:damage',
      // 4.4 Accounting (reports/journal only)
      'account:read', 'journal:create', 'journal:read', 'journal:post',
      'trial_balance:read', 'profit_loss:read', 'balance_sheet:read',
      'report:read',
      // 4.5 Customers
      'customer:create', 'customer:read', 'customer:update', 'customer:delete',
      'customer:export',
      // 4.6 Reports & Analytics (Phase 8)
      'report:sales', 'report:purchases', 'report:inventory',
      'report:financial', 'report:export',
      // 4.7 Administration
      'user:create', 'user:read', 'user:update',
      'settings:update', 'backup:create', 'backup:restore', 'audit_log:read',
    },
    'Manager': {
      // 4.1
      'sale:create', 'sale:read', 'sale:update', 'sale:return',
      'sale:approve_discount', 'payment:create', 'payment:read',
      'quotation:create', 'quotation:read',
      // 4.2
      'purchase:create', 'purchase:read', 'purchase:return',
      'purchase_order:create', 'supplier:create', 'supplier:read', 'supplier:update',
      // 4.3
      'product:create', 'product:read', 'product:update',
      'category:create', 'category:read', 'category:update',
      'brand:create', 'brand:read', 'brand:update',
      'unit:create', 'unit:read', 'unit:update',
      'warehouse:read',
      'batch:read', 'batch:update',
      'inventory:read', 'inventory:transfer', 'inventory:damage',
      // 4.5
      'customer:create', 'customer:read', 'customer:update', 'customer:export',
      // 4.6 Reports & Analytics (Phase 8) – view only, no financial, no export
      'report:sales', 'report:purchases', 'report:inventory',
    },
    'Cashier': {
      // 4.1 (create sales/payments, read own history)
      'sale:create', 'sale:read', 'sale:update', 'payment:create', 'payment:read',
      // 4.3 (limited product read)
      'product:read',
      // 4.5
      'customer:create', 'customer:read',
    },
    'Accountant': {
      // 4.2 (read-only purchases/suppliers)
      'purchase:read', 'supplier:read',
      // 4.4 (full accounting)
      'account:create', 'account:read', 'account:update', 'account:delete',
      'journal:create', 'journal:read', 'journal:post', 'trial_balance:read',
      'profit_loss:read', 'balance_sheet:read', 'report:read',
      // 4.6 Reports & Analytics (Phase 8)
      'report:sales', 'report:purchases', 'report:inventory',
      'report:financial', 'report:export',
    },
    'Inventory Manager': {
      // 4.3 – full product & stock management, no sales/purchases/finance
      'product:create', 'product:read', 'product:update', 'product:delete',
      'category:create', 'category:read', 'category:update', 'category:delete',
      'brand:create', 'brand:read', 'brand:update', 'brand:delete',
      'unit:create', 'unit:read', 'unit:update', 'unit:delete',
      'warehouse:create', 'warehouse:read', 'warehouse:update',
      'batch:read', 'batch:update',
      'inventory:read', 'inventory:transfer', 'inventory:adjust', 'inventory:damage',
      // 4.6 Reports & Analytics – inventory reports & low stock alerts
      'report:inventory',
    },
  };

  /// Union of *every* permission string used anywhere in the system. Owner
  /// implicitly receives all of these.
  static Set<String> get allPermissions {
    final set = <String>{};
    for (final permissions in rolePermissions.values) {
      set.addAll(permissions);
    }
    // Owner-only permissions not held by any other role (Section 4.4 / 4.7).
    set.addAll({
      'user:delete',
      'role:assign',
      'business:change_type',
      'period:close',
    });
    return set;
  }

  /// Create roles (if missing) and grant their permissions idempotently.
  ///
  /// Returns `roleName -> roleId` map for the six system roles.
  ///
  /// The caller owns the surrounding transaction (`SetupController` wraps
  /// business + roles + owner creation in one `BEGIN IMMEDIATE … COMMIT`,
  /// mirroring how `DatabaseHelper.runMigrations` wraps `SchemaV1.createAll`).
  /// This method therefore performs bare statements only and never issues
  /// `BEGIN`/`COMMIT` itself.
  Map<String, int> seed() {
    final now = DateTime.now().toUtc().toIso8601String();
    final roleIds = <String, int>{};

    for (final entry in systemRoles.entries) {
      final existing = _db.select(
        'SELECT id FROM roles WHERE name = ?;',
        [entry.key],
      );
      int roleId;
      if (existing.isNotEmpty) {
        roleId = existing.first['id'] as int;
      } else {
        _db.execute(
          'INSERT INTO roles (name, description, is_system, is_active, created_at) '
          'VALUES (?, ?, 1, 1, ?);',
          [entry.key, entry.value, now],
        );
        roleId = _db.lastInsertRowId;
      }
      roleIds[entry.key] = roleId;

      final grants =
          entry.key == 'Owner' ? allPermissions : rolePermissions[entry.key]!;
      for (final perm in grants) {
        final sep = perm.indexOf(':');
        _db.execute(
          'INSERT OR IGNORE INTO permissions (role_id, resource, action) '
          'VALUES (?, ?, ?);',
          [roleId, perm.substring(0, sep), perm.substring(sep + 1)],
        );
      }
    }
    return roleIds;
  }

  /// Look up the id of a system role by name (null when not found).
  int? roleIdFor(String name) {
    final rows = _db.select('SELECT id FROM roles WHERE name = ?;', [name]);
    if (rows.isEmpty) return null;
    return rows.first['id'] as int;
  }
}
