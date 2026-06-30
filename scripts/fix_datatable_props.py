#!/usr/bin/env python3
"""Add missing DataTable properties: dataRowMinHeight, dataRowMaxHeight, columnSpacing, horizontalMargin, dataRowColor."""
import os, re

PAGES_DIR = "/home/z/my-project/virent-dart/mobile/lib/features/admin_web/pages"

fixes = 0

DATATABLE_PROPS = """dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) return const Color(0xFFF1F4F8);
              return Colors.white;
            }),
            dataRowMinHeight: 40,
            dataRowMaxHeight: 40,
            columnSpacing: 24,
            horizontalMargin: 12,"""

for fn in sorted(os.listdir(PAGES_DIR)):
    if not fn.endswith('.dart'): continue
    fp = os.path.join(PAGES_DIR, fn)
    with open(fp) as f: c = f.read()
    orig = c
    
    # Find DataTable( and add missing properties after headingTextStyle
    if 'DataTable(' in c and 'dataRowMinHeight' not in c:
        # Add properties after headingTextStyle line
        c = re.sub(
            r'(headingTextStyle:[^\n]+\n)',
            r'\1            ' + DATATABLE_PROPS + '\n',
            c,
            count=1
        )
    
    if c != orig:
        with open(fp, 'w') as f: f.write(c)
        fixes += 1
        print(f"Fixed: {fn}")

print(f"\n=== {fixes} files fixed ===")
