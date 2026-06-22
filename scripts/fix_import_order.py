#!/usr/bin/env python3
"""Fix import order: move json_helpers.dart import after library directive."""

import os
import re

MODELS_DIR = "/home/z/my-project/sparkrentals-monorepo/sparkrentals-monorepo/virent-dart/mobile/lib/core/backend/models"

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    import_line = "import 'json_helpers.dart';"
    if import_line not in content:
        return False
    
    lines = content.split('\n')
    import_idx = None
    library_idx = None
    
    for i, line in enumerate(lines):
        if line.strip() == import_line:
            import_idx = i
        if line.strip().startswith('library ') and import_idx is not None and library_idx is None:
            library_idx = i
    
    if import_idx is not None and library_idx is not None and import_idx < library_idx:
        # Move import after library directive
        lines.pop(import_idx)
        # Find the end of library directive (it may have a blank line after it)
        insert_idx = library_idx + 1  # after the library line
        # Skip blank lines after library
        while insert_idx < len(lines) and lines[insert_idx].strip() == '':
            insert_idx += 1
        lines.insert(insert_idx, import_line)
        
        with open(filepath, 'w') as f:
            f.write('\n'.join(lines))
        return True
    
    return False

def main():
    fixed = []
    for filename in sorted(os.listdir(MODELS_DIR)):
        if not filename.endswith('_model.dart'):
            continue
        filepath = os.path.join(MODELS_DIR, filename)
        if fix_file(filepath):
            fixed.append(filename)
            print(f"  Fixed import order: {filename}")
    print(f"\nFixed {len(fixed)} files")

if __name__ == "__main__":
    main()
