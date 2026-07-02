#!/usr/bin/env python3
"""Fix UI consistency: titles, Card radius, DataTable headingTextStyle."""
import os, re

PAGES_DIR = "/home/z/my-project/virent-dart/mobile/lib/features/admin_web/pages"

fixes = 0

for fn in sorted(os.listdir(PAGES_DIR)):
    if not fn.endswith('.dart'): continue
    fp = os.path.join(PAGES_DIR, fn)
    with open(fp) as f: c = f.read()
    orig = c
    
    # 1. Fix title fontSize: 24 -> 22, 26 -> 22, 18 -> 22 (only for page titles)
    # Page titles are usually in Text('Title', style: TextStyle(fontSize: NN...
    # Don't touch stat card values or other non-title text
    c = re.sub(
        r"(Text\(\s*['\"][^'\"]+['\"][^)]*style:\s*TextStyle\(\s*)fontSize:\s*24(\s*,\s*fontWeight:\s*FontWeight\.w400\s*,\s*color:\s*Color\(0xFF1B2A4E\)\s*\))",
        r"\1fontSize: 22\2",
        c
    )
    c = re.sub(
        r"(style:\s*TextStyle\(\s*)fontSize:\s*26(\s*,\s*fontWeight:\s*FontWeight\.w400\s*,\s*color:\s*Color\(0xFF1B2A4E\)\s*\))",
        r"\1fontSize: 22\2",
        c
    )
    
    # 2. Fix Card borderRadius: 4 -> 8
    c = c.replace("borderRadius: BorderRadius.circular(4)", "borderRadius: BorderRadius.circular(8)")
    
    # 3. Add headingTextStyle to DataTables that are missing it
    # Find DataTable( and check if headingTextStyle is already there
    def add_heading_style(match):
        dt_content = match.group(0)
        if 'headingTextStyle' in dt_content:
            return dt_content
        # Add headingTextStyle after headingRowColor
        if 'headingRowColor' in dt_content:
            dt_content = dt_content.replace(
                'headingRowColor:',
                "headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B2A4E)),\n                    headingRowColor:",
                1
            )
        else:
            # Add after DataTable(
            dt_content = dt_content.replace(
                'DataTable(',
                'DataTable(\n                    headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B2A4E)),',
                1
            )
        return dt_content
    
    c = re.sub(r'DataTable\([^)]*\)', add_heading_style, c, flags=re.DOTALL)
    
    if c != orig:
        with open(fp, 'w') as f: f.write(c)
        fixes += 1
        print(f"Fixed: {fn}")

print(f"\n=== {fixes} files fixed ===")
