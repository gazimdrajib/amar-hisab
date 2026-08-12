import re, glob, os

def fix_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content

    # 1. Fix method signatures: (Request req, String id) -> (Request req)
    # Covers id, productId, warehouseId, query, etc.
    content = re.sub(r'\(Request req, String \w+\)', '(Request req)', content)

    # 2. Fix variable assignments: int id = int.parse(id); -> int id = int.parse(req.params['id'] ?? '0');
    content = re.sub(r'int id = int\.parse\(id\);', r'int id = int.parse(req.params[\'id\'] ?? \'0\');', content)
    content = re.sub(r'int productId = int\.parse\(productId\);', r'int productId = int.parse(req.params[\'productId\'] ?? \'0\');', content)
    content = re.sub(r'int warehouseId = int\.parse\(warehouseId\);', r'int warehouseId = int.parse(req.params[\'warehouseId\'] ?? \'0\');', content)
    content = re.sub(r'String query = query;', r'String query = req.params[\'query\'] ?? \'\';', content)

    # 3. Fix the 'num' type error in product_controller (rename helper function)
    # Replace: double num(String key) with double parseDouble(String key)
    content = re.sub(r'double num\(String key\)', r'double parseDouble(String key)', content)
    # Also rename any calls to this function (if they used 'num(')
    content = re.sub(r'num\(', r'parseDouble(', content)

    if content != original:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ Fixed {file_path}")
    else:
        print(f"⏭️  No changes in {file_path}")

# Find all controller files
files = glob.glob('lib/**/controllers/*.dart', recursive=True)
for f in files:
    fix_file(f)

print("🎉 All controllers updated.")
