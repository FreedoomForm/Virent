#!/usr/bin/env python3
"""
Properly replace duplicated helper functions in Virent model files.
Uses proper parsing instead of regex to handle multi-line functions.
"""

import os
import re

MODELS_DIR = "/home/z/my-project/sparkrentals-monorepo/sparkrentals-monorepo/virent-dart/mobile/lib/core/backend/models"

HELPERS = ["stringifyId", "stringifyIdNullable", "toInt", "toDouble", "asString", "parseDate"]

def find_and_remove_helpers(lines):
    """Find top-level helper function definitions and remove them."""
    new_lines = []
    i = 0
    removed = False
    
    while i < len(lines):
        stripped = lines[i].rstrip('\n')
        
        # Check if this line starts a top-level helper function
        is_helper = False
        for name in HELPERS:
            # Match: Type _funcName(dynamic param) {
            pattern = rf'^(?:String|int|double|DateTime)\??\s+_{name}\s*\(dynamic\s+\w+\)\s*\{{'
            if re.match(pattern, stripped.strip()):
                is_helper = True
                break
            # Match: Type _funcName(dynamic param)  (opening brace on next line)
            pattern2 = rf'^(?:String|int|double|DateTime)\??\s+_{name}\s*\(dynamic\s+\w+\)\s*$'
            if re.match(pattern2, stripped.strip()):
                if i + 1 < len(lines) and lines[i + 1].strip().startswith('{'):
                    is_helper = True
                    break
        
        if is_helper:
            # Also remove preceding doc comments (/// lines) and blank lines before them
            # Go back and remove doc comment block
            while new_lines:
                last = new_lines[-1].rstrip('\n')
                if last.strip().startswith('///'):
                    new_lines.pop()
                elif last.strip() == '':
                    # Check if line before this is a doc comment
                    if len(new_lines) >= 2 and new_lines[-2].rstrip('\n').strip().startswith('///'):
                        new_lines.pop()
                    else:
                        break
                else:
                    break
            
            # Skip the function definition line
            brace_depth = 0
            while i < len(lines):
                line = lines[i].rstrip('\n')
                brace_depth += line.count('{') - line.count('}')
                i += 1
                if brace_depth <= 0:
                    break
            removed = True
            continue
        
        new_lines.append(lines[i])
        i += 1
    
    return new_lines, removed

def add_import_if_needed(content):
    """Add import 'json_helpers.dart' if not present."""
    import_line = "import 'json_helpers.dart';"
    if import_line in content:
        return content
    
    lines = content.split('\n')
    # Find the last import line
    last_import_idx = -1
    for i, line in enumerate(lines):
        if line.strip().startswith('import '):
            last_import_idx = i
    
    if last_import_idx >= 0:
        lines.insert(last_import_idx + 1, import_line)
    else:
        lines.insert(0, import_line)
    
    return '\n'.join(lines)

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    lines = content.split('\n')
    new_lines, removed = find_and_remove_helpers(lines)
    
    if not removed:
        return False
    
    new_content = '\n'.join(new_lines)
    
    # Add import
    new_content = add_import_if_needed(new_content)
    
    # Clean up excessive blank lines
    new_content = re.sub(r'\n{4,}', '\n\n\n', new_content)
    
    # Ensure file ends with newline
    if not new_content.endswith('\n'):
        new_content += '\n'
    
    with open(filepath, 'w') as f:
        f.write(new_content)
    
    return True

def replace_calls(filepath):
    """Replace _funcName() calls with funcName() (remove underscore prefix)."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    changed = False
    for name in HELPERS:
        old = f'_{name}('
        new = f'{name}('
        if old in content:
            content = content.replace(old, new)
            changed = True
    
    if changed:
        with open(filepath, 'w') as f:
            f.write(content)
    
    return changed

def main():
    changed_files = []
    call_files = []
    
    for filename in sorted(os.listdir(MODELS_DIR)):
        if not filename.endswith('_model.dart'):
            continue
        filepath = os.path.join(MODELS_DIR, filename)
        if process_file(filepath):
            changed_files.append(filename)
            print(f"  Removed helpers: {filename}")
        if replace_calls(filepath):
            call_files.append(filename)
            print(f"  Updated calls: {filename}")
    
    print(f"\nRemoved helpers from {len(changed_files)} files")
    print(f"Updated calls in {len(call_files)} files")
    
    # Update models.dart barrel file
    barrel = os.path.join(MODELS_DIR, "models.dart")
    with open(barrel, 'r') as f:
        content = f.read()
    
    if "json_helpers.dart" not in content:
        content = content.replace(
            "library;\n",
            "library;\n\nexport 'json_helpers.dart'\n    show stringifyId, stringifyIdNullable, toInt, toDouble, asString, parseDate;\n"
        )
        with open(barrel, 'w') as f:
            f.write(content)
        print("  Updated models.dart barrel file")

if __name__ == "__main__":
    main()
