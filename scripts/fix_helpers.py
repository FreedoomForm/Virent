#!/usr/bin/env python3
"""Fix partially-removed helper functions in Virent model files."""

import re
import os

MODELS_DIR = "/home/z/my-project/sparkrentals-monorepo/sparkrentals-monorepo/virent-dart/mobile/lib/core/backend/models"

HELPERS = ["stringifyId", "stringifyIdNullable", "toInt", "toDouble", "asString", "parseDate"]

def fix_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    # Find and remove leftover helper function fragments
    new_lines = []
    skip_mode = False
    brace_depth = 0
    found_doc_comment = False
    
    i = 0
    changed = False
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        
        # Detect start of a helper function definition (with or without underscore)
        for name in HELPERS:
            # Match: Type _funcName(dynamic ...) { or Type funcName(dynamic ...) {
            pattern = rf'^(?:String|int|double|DateTime)\??\s+_?{name}\s*\(dynamic\s+\w+\)\s*\{{'
            if re.match(pattern, stripped):
                # Found a function definition - skip it entirely
                skip_mode = True
                brace_depth = stripped.count('{') - stripped.count('}')
                changed = True
                i += 1
                # Also skip preceding doc comments
                j = len(new_lines) - 1
                while j >= 0 and (new_lines[j].strip().startswith('///') or new_lines[j].strip() == ''):
                    if new_lines[j].strip().startswith('///'):
                        new_lines.pop(j)
                        j -= 1
                    elif new_lines[j].strip() == '' and j > 0 and new_lines[j-1].strip().startswith('///'):
                        new_lines.pop(j)
                        j -= 1
                    else:
                        break
                continue
            
            # Also detect function signature on one line followed by body on next lines
            pattern2 = rf'^(?:String|int|double|DateTime)\??\s+_?{name}\s*\(dynamic\s+\w+\)\s*$'
            if re.match(pattern2, stripped):
                # Check if next line starts with {
                if i + 1 < len(lines) and lines[i+1].strip().startswith('{'):
                    skip_mode = True
                    brace_depth = 0
                    changed = True
                    i += 1
                    # Skip preceding doc comments
                    j = len(new_lines) - 1
                    while j >= 0 and (new_lines[j].strip().startswith('///') or new_lines[j].strip() == ''):
                        if new_lines[j].strip().startswith('///'):
                            new_lines.pop(j)
                            j -= 1
                        elif new_lines[j].strip() == '' and j > 0 and new_lines[j-1].strip().startswith('///'):
                            new_lines.pop(j)
                            j -= 1
                        else:
                            break
                    continue
        
        if skip_mode:
            brace_depth += stripped.count('{') - stripped.count('}')
            if brace_depth <= 0:
                skip_mode = False
            i += 1
            continue
        
        new_lines.append(line)
        i += 1
    
    if not changed:
        return False
    
    # Remove excessive blank lines
    result = ''.join(new_lines)
    result = re.sub(r'\n{4,}', '\n\n\n', result)
    
    with open(filepath, 'w') as f:
        f.write(result)
    
    return True

def main():
    changed_files = []
    for filename in sorted(os.listdir(MODELS_DIR)):
        if not filename.endswith('_model.dart'):
            continue
        filepath = os.path.join(MODELS_DIR, filename)
        if fix_file(filepath):
            changed_files.append(filename)
            print(f"  Fixed {filename}")
    
    print(f"\nFixed {len(changed_files)} files")

if __name__ == "__main__":
    main()
