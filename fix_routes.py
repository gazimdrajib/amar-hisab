import re, glob

files = [
    "lib/modules/auth/presentation/controllers/user_controller.dart",
    "lib/modules/inventory/presentation/controllers/inventory_controller.dart",
    "lib/modules/products/presentation/controllers/product_controller.dart",
    # Add any other controllers with similar issues
]

for file in files:
    try:
        with open(file, 'r', encoding='utf-8') as f:
            content = f.read()
        original = content

        # Fix pattern: r.get('/<id|[0-9]+>', requirePermission(...)(_handler));
        # Replace with: r.get('/<id|[0-9]+>', (req) => _handler(req, req.params['id']));
        pattern = r"r\.(get|put|delete|post|patch)\(\s*'/<id\|\[0-9\]\+>',\s*requirePermission\([^)]*\)\s*\(\s*_([a-zA-Z0-9_]+)\s*\)\s*\);"
        replacement = r"r.\1('/<id|[0-9]+>', (req) => _\2(req, req.params['id']));"
        content = re.sub(pattern, replacement, content)

        # Fix pattern for search: r.get('/search/<query>', requirePermission(...)(_search));
        pattern2 = r"r\.(get)\(\s*'/search/<query>',\s*requirePermission\([^)]*\)\s*\(\s*_([a-zA-Z0-9_]+)\s*\)\s*\);"
        replacement2 = r"r.\1('/search/<query>', (req) => _\2(req, req.params['query']));"
        content = re.sub(pattern2, replacement2, content)

        # Fix pattern for stock routes: /stock/<productId|[0-9]+> etc.
        pattern3 = r"r\.(get)\(\s*'/stock/<productId\|\[0-9\]\+>',\s*requirePermission\([^)]*\)\s*\(\s*_([a-zA-Z0-9_]+)\s*\)\s*\);"
        replacement3 = r"r.\1('/stock/<productId|[0-9]+>', (req) => _\2(req, req.params['productId']));"
        content = re.sub(pattern3, replacement3, content)

        pattern4 = r"r\.(get)\(\s*'/stock/<warehouseId\|\[0-9\]\+>',\s*requirePermission\([^)]*\)\s*\(\s*_([a-zA-Z0-9_]+)\s*\)\s*\);"
        replacement4 = r"r.\1('/stock/<warehouseId|[0-9]+>', (req) => _\2(req, req.params['warehouseId']));"
        content = re.sub(pattern4, replacement4, content)

        if content != original:
            with open(file, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Fixed {file}")
        else:
            print(f"⏭️  No changes in {file}")
    except FileNotFoundError:
        print(f"⚠️  File not found: {file}")

print("🎉 All route fixes applied.")
