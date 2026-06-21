#!/usr/bin/env python3
"""Replace duplicated helper functions in Virent model files with imports from json_helpers.dart."""

import re
import os

MODELS_DIR = "/home/z/my-project/sparkrentals-monorepo/sparkrentals-monorepo/virent-dart/mobile/lib/core/backend/models"

HELPERS = ["stringifyId", "stringifyIdNullable", "toInt", "toDouble", "asString", "parseDate"]

def remove_helper_functions(content):
    """Remove all private helper function definitions from content."""
    changed = False
    for name in HELPERS:
        # Match function definitions like:
        # String _stringifyId(dynamic value) { ... }
        # int _toInt(dynamic value) { ... }
        # DateTime? _parseDate(dynamic value) { ... }
        pattern = rf'^(?:String|int|double|DateTime)\??\s+_{name}\s*\(dynamic\s+\w+\)\s*\{{[^}}]*\}}\s*$\n?'
        new_content = re.sub(pattern, '', content, flags=re.MULTILINE)
        if new_content != content:
            changed = True
            content = new_content
    return content, changed

def add_import(content):
    """Add json_helpers.dart import if not present."""
    import_line = "import 'json_helpers.dart';"
    if import_line in content:
        return content
    
    # Find the last import line
    imports = list(re.finditer(r"^import\s+.*;\s*$", content, re.MULTILINE))
    if imports:
        last_import = imports[-1]
        pos = last_import.end()
        content = content[:pos] + '\n' + import_line + content[pos:]
    else:
        content = import_line + '\n\n' + content
    
    return content

def clean_blank_lines(content):
    """Reduce 3+ consecutive blank lines to 2."""
    return re.sub(r'\n{4,}', '\n\n\n', content)

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    content, has_helpers = remove_helper_functions(content)
    
    if not has_helpers:
        return False
    
    content = add_import(content)
    content = clean_blank_lines(content)
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    return True

def main():
    changed_files = []
    for filename in sorted(os.listdir(MODELS_DIR)):
        if not filename.endswith('_model.dart'):
            continue
        filepath = os.path.join(MODELS_DIR, filename)
        if process_file(filepath):
            changed_files.append(filename)
            print(f"  OK {filename}")
    
    print(f"\nProcessed {len(changed_files)} files")
    
    # Update models.dart barrel file
    barrel = os.path.join(MODELS_DIR, "models.dart")
    with open(barrel, 'r') as f:
        content = f.read()
    
    if "json_helpers.dart" not in content:
        content = content.replace(
            "library;\n",
            "library;\n\nexport 'json_helpers.dart' show stringifyId, stringifyIdNullable, toInt, toDouble, asString, parseDate;\n"
        )
        with open(barrel, 'w') as f:
            f.write(content)
        print("  OK Updated models.dart barrel file")

if __name__ == "__main__":
    main()
