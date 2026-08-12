import re, os, glob

files = glob.glob('lib/modules/**/controllers/*.dart', recursive=True)

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern: r.method('/<id|[0-9]+>', requirePermission(...)(_handler));
    # Replace with: r.method('/<id|[0-9]+>', (req) => _handler(req, req.params['id']));
    pattern = r"r\.(get|put|delete|post|patch)\(\s*'/<id\|\[0-9\]\+>',\s*requirePermission\([^)]*\)\s*\(\s*_([a-zA-Z0-9_]+)\s*\)\s*\);"
    replacement = r"r.\1('/<id|[0-9]+>', (req) => _\2(req, req.params['id']));"
    
    new_content = re.sub(pattern, replacement, content)
    
    # Also handle routes with productId and warehouseId
    pattern2 = r"r\.(get)\(\s*'/stock/<productId\|\[0-9\]\+>',\s*requirePermission\([^)]*\)\s*\(\s*_([a-zA-Z0-9_]+)\s*\)\s*\);"
    replacement2 = r"r.\1('/stock/<productId|[0-9]+>', (req) => _\2(req, req.params['productId']));"
    new_content = re.sub(pattern2, replacement2, new_content)
    
    pattern3 = r"r\.(get)\(\s*'/stock/<warehouseId\|\[0-9\]\+>',\s*requirePermission\([^)]*\)\s*\(\s*_([a-zA-Z0-9_]+)\s*\)\s*\);"
    replacement3 = r"r.\1('/stock/<warehouseId|[0-9]+>', (req) => _\2(req, req.params['warehouseId']));"
    new_content = re.sub(pattern3, replacement3, new_content)
    
    if content != new_content:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"✅ Fixed {file}")
    else:
        print(f"⏭️  No changes in {file}")
