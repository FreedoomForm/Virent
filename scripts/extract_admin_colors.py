#!/usr/bin/env python3
"""
Replace hardcoded Color(0xFF...) literals with shared constants from
admin_colors.dart, and add the import to each modified page file.

Order matters: `const Color(...)` is replaced first (stripping `const`),
then plain `Color(...)` is replaced. This avoids producing `const adminPrimary`
which would be invalid Dart syntax.
"""

import os
import sys

PAGES_DIR = '/home/z/my-project/virent-dart/mobile/lib/features/admin_web/pages'
IMPORT_STATEMENT = "import '../widgets/admin_colors.dart';"

# Order matters: const-prefixed patterns MUST come before non-const ones
# so that `const Color(0xFFxxxxxx)` is replaced with `adminXxx` (dropping
# `const`) BEFORE `Color(0xFFxxxxxx)` matches as a substring.
COLOR_MAP = [
    ('const Color(0xFF7C69EF)', 'adminPrimary'),
    ('Color(0xFF7C69EF)', 'adminPrimary'),
    ('const Color(0xFF1B2A4E)', 'adminTextDark'),
    ('Color(0xFF1B2A4E)', 'adminTextDark'),
    ('const Color(0xFF868686)', 'adminTextGray'),
    ('Color(0xFF868686)', 'adminTextGray'),
    ('const Color(0xFF6D737A)', 'adminTextSecondary'),
    ('Color(0xFF6D737A)', 'adminTextSecondary'),
    ('const Color(0xFF42BA96)', 'adminSuccess'),
    ('Color(0xFF42BA96)', 'adminSuccess'),
    ('const Color(0xFFDF4759)', 'adminDanger'),
    ('Color(0xFFDF4759)', 'adminDanger'),
    ('const Color(0xFFFFC107)', 'adminWarning'),
    ('Color(0xFFFFC107)', 'adminWarning'),
    ('const Color(0xFF467FD0)', 'adminInfo'),
    ('Color(0xFF467FD0)', 'adminInfo'),
    ('const Color(0xFFF1F4F8)', 'adminBgLight'),
    ('Color(0xFFF1F4F8)', 'adminBgLight'),
    ('const Color(0xFFD9E2EF)', 'adminBorder'),
    ('Color(0xFFD9E2EF)', 'adminBorder'),
]


def add_import(content: str) -> str:
    """Insert the admin_colors import after the last existing import line."""
    if IMPORT_STATEMENT in content:
        return content  # already present
    lines = content.split('\n')
    last_import_idx = -1
    for i, line in enumerate(lines):
        if line.startswith('import '):
            last_import_idx = i
    if last_import_idx >= 0:
        lines.insert(last_import_idx + 1, IMPORT_STATEMENT)
        return '\n'.join(lines)
    # No imports — prepend
    return IMPORT_STATEMENT + '\n' + content


def main():
    modified_files = []
    total_replacements = 0
    per_color_counts = {}
    per_file_counts = {}

    for fname in sorted(os.listdir(PAGES_DIR)):
        if not fname.endswith('.dart'):
            continue
        fpath = os.path.join(PAGES_DIR, fname)
        with open(fpath, 'r') as f:
            content = f.read()

        original = content
        file_replacements = 0
        for old, new in COLOR_MAP:
            count = content.count(old)
            if count > 0:
                content = content.replace(old, new)
                file_replacements += count
                per_color_counts[new] = per_color_counts.get(new, 0) + count

        if content != original:
            content = add_import(content)
            with open(fpath, 'w') as f:
                f.write(content)
            modified_files.append(fname)
            total_replacements += file_replacements
            per_file_counts[fname] = file_replacements

    print(f"Total files modified: {len(modified_files)}")
    print(f"Total replacements:    {total_replacements}")
    print()
    print("Per-color counts:")
    for color, count in sorted(per_color_counts.items(), key=lambda x: -x[1]):
        print(f"  {color:24s}: {count}")
    print()
    print("Per-file counts (top 15):")
    for fname, count in sorted(per_file_counts.items(), key=lambda x: -x[1])[:15]:
        print(f"  {fname:40s}: {count}")


if __name__ == '__main__':
    main()
