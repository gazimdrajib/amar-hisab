import glob, re

files = glob.glob('lib/**/controllers/*.dart', recursive=True)

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content

    # Add ! to all req.params['key'] where used as argument
    # Pattern: req.params['id'] -> req.params['id']!
    # We need to handle single and double quotes
    content = re.sub(r"req\.params\['([^']+)'\]", r"req.params['\1']!", content)
    content = re.sub(r'req\.params\["([^"]+)"\]', r'req.params["\1"]!', content)

    if content != original:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ Fixed {file}")

print("🎉 All null safety fixes applied.")
