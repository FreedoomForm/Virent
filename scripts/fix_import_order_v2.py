#!/usr/bin/env python3
"""Fix import order: move json_helpers.dart import after library directive."""

import os

MODELS_DIR = "/home/z/my-project/sparkrentals-monorepo/sparkrentals-monorepo/virent-dart/mobile/lib/core/backend/models"

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    import_line = "import 'json_helpers.dart';"
    if import_line not in content:
        return False
    
    lines = content.split('\n')
    
    # Find import line and library line
    import_indices = [i for i, line in enumerate(lines) if line.strip() == import_line]
    library_indices = [i for i, line in enumerate(lines) if line.strip().startswith('library ') or line.strip() == 'library;']
    
    if not import_indices:
        return False
    
    import_idx = import_indices[0]
    
    # If there's a library directive and import is before it, move import after it
    if library_indices and import_idx < library_indices[0]:
        lib_idx = library_indices[0]
        # Remove the import from its current position
        lines.pop(import_idx)
        # Insert after library line (adjust index since we removed a line)
        if lib_idx > import_idx:
            lib_idx -= 1
        # Find good insertion point: after library; line + blank line
        insert_idx = lib_idx + 1
        # Skip blank lines after library
        while insert_idx < len(lines) and lines[insert_idx].strip() == '':
            insert_idx += 1
        lines.insert(insert_idx, '')
        lines.insert(insert_idx + 1, import_line)
        
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
            print(f"  Fixed: {filename}")
    print(f"\nFixed {len(fixed)} files")

if __name__ == "__main__":
    main()
