import re

# File: user_controller.dart – fix _changePassword route
with open('lib/modules/auth/presentation/controllers/user_controller.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the problematic line: requirePermission(...)(_changePassword)
content = content.replace(
    "requirePermission(_checker, 'user', 'update')(_changePassword)",
    "requirePermission(_checker, 'user', 'update')((req) => _changePassword(req, req.params['id']))"
)

# Also fix the other user routes (though they may not error, we fix them anyway)
content = content.replace(
    "requirePermission(_checker, 'user', 'read')(_get)",
    "requirePermission(_checker, 'user', 'read')((req) => _get(req, req.params['id']))"
)
content = content.replace(
    "requirePermission(_checker, 'user', 'update')(_update)",
    "requirePermission(_checker, 'user', 'update')((req) => _update(req, req.params['id']))"
)
content = content.replace(
    "requirePermission(_checker, 'user', 'delete')(_delete)",
    "requirePermission(_checker, 'user', 'delete')((req) => _delete(req, req.params['id']))"
)

with open('lib/modules/auth/presentation/controllers/user_controller.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("✅ Fixed user_controller.dart")

# File: inventory_controller.dart – fix all routes
with open('lib/modules/inventory/presentation/controllers/inventory_controller.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "requirePermission(_checker, 'inventory', 'read')(_stockByProduct)",
    "requirePermission(_checker, 'inventory', 'read')((req) => _stockByProduct(req, req.params['productId']))"
)
content = content.replace(
    "requirePermission(_checker, 'inventory', 'read')(_stockByWarehouse)",
    "requirePermission(_checker, 'inventory', 'read')((req) => _stockByWarehouse(req, req.params['warehouseId']))"
)
content = content.replace(
    "requirePermission(_checker, 'batch', 'read')(_batches)",
    "requirePermission(_checker, 'batch', 'read')((req) => _batches(req, req.params['productId']))"
)
content = content.replace(
    "requirePermission(_checker, 'inventory', 'read')(_movements)",
    "requirePermission(_checker, 'inventory', 'read')((req) => _movements(req, req.params['productId']))"
)

with open('lib/modules/inventory/presentation/controllers/inventory_controller.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("✅ Fixed inventory_controller.dart")

print("🎉 All remaining errors fixed.")
