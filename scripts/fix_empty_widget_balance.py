#!/usr/bin/env python3
"""
Fix the empty widget missing closing paren for Center in 8 admin pages.

The empty widget added by fix_admin_ux.py is missing 1 closing `)` for the
outermost Center widget. Pattern to fix:

  ...Text('Нет данных', style: TextStyle(...))) ])) : SingleChildScrollView(...

should become:

  ...Text('Нет данных', style: TextStyle(...))) ]))) : SingleChildScrollView(...
"""

import os

PAGES_DIR = "/home/z/my-project/virent-dart/mobile/lib/features/admin_web/pages"
FILES = [
    "iot_page.dart",
    "sms_logs_page.dart",
    "tariffs_page.dart",
    "tariffs_subscriptions_page.dart",
    "tariff_subtariffs_page.dart",
    "settings_drivers_page.dart",
    "settings_scooter_groups_page.dart",
    "task_technicians_page.dart",
]

# The exact broken pattern (missing 1 close paren for Center)
OLD = "fontSize: 13))])) : SingleChildScrollView"
NEW = "fontSize: 13))]))) : SingleChildScrollView"


def main():
    fixed = 0
    for fn in FILES:
        path = os.path.join(PAGES_DIR, fn)
        if not os.path.exists(path):
            print(f"MISS: {fn}")
            continue
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        if OLD in content:
            content = content.replace(OLD, NEW)
            with open(path, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"  FIXED: {fn}")
            fixed += 1
        else:
            print(f"  NO MATCH: {fn}")
    print(f"Total fixed: {fixed}")


if __name__ == "__main__":
    main()
