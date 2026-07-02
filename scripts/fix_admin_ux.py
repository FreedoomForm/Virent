#!/usr/bin/env python3
"""
Fix UX issues in 8 admin DataTable pages:
  1. Add missing trailing commas in DataRow DataCell entries (syntax error!)
  2. Add tooltips to chevron_left/chevron_right pagination IconButtons
  3. Add empty state widget when filtered/pageItems is empty
  4. Add onSubmitted (Enter key) to search TextField
"""

import os
import re

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

DATACELL_NO_COMMA = re.compile(
    r"(DataCell\(Text\('\$\{item\[[^\]]+\] \?\? ''\}'\)\))(\s*\n)"
)
CHEVRON_LEFT = re.compile(
    r"IconButton\(icon: const Icon\(Icons\.chevron_left, size: 16\), onPressed:"
)
CHEVRON_RIGHT = re.compile(
    r"IconButton\(icon: const Icon\(Icons\.chevron_right, size: 16\), onPressed:"
)
SEARCH_ONCHANGED = re.compile(
    r"onChanged: \(v\) => setState\(\(\) \{ _query = v; _currentPage = 1; \}\),"
)
DATATABLE_WRAP = re.compile(
    r"child: SingleChildScrollView\(child: DataTable\("
)
CLOSING_PATTERN = re.compile(r"toList\(\)\)\)\)\)\),")


def fix_file(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    original = content
    stats = {"commas": 0, "tooltips": 0, "empty_state": 0, "on_submitted": 0}

    # 1. Add trailing commas to DataCell entries
    def _add_comma(m):
        stats["commas"] += 1
        return m.group(1) + "," + m.group(2)
    content = DATACELL_NO_COMMA.sub(_add_comma, content)

    # 2. Add tooltips to chevron IconButtons
    new_content = CHEVRON_LEFT.sub(
        "IconButton(tooltip: '\u041f\u0440\u0435\u0434\u044b\u0434\u0443\u0449\u0430\u044f \u0441\u0442\u0440\u0430\u043d\u0438\u0446\u0430', "
        "icon: const Icon(Icons.chevron_left, size: 16), onPressed:",
        content,
    )
    if new_content != content:
        stats["tooltips"] += 1
        content = new_content
    new_content = CHEVRON_RIGHT.sub(
        "IconButton(tooltip: '\u0421\u043b\u0435\u0434\u0443\u044e\u0449\u0430\u044f \u0441\u0442\u0440\u0430\u043d\u0438\u0446\u0430', "
        "icon: const Icon(Icons.chevron_right, size: 16), onPressed:",
        content,
    )
    if new_content != content:
        stats["tooltips"] += 1
        content = new_content

    # 3. Add onSubmitted (Enter key) to search TextField
    if "onSubmitted:" not in content:
        def _add_on_submitted(m):
            stats["on_submitted"] += 1
            return (
                m.group(0)
                + " onSubmitted: (v) => setState(() { _query = v; _currentPage = 1; }),"
            )
        content = SEARCH_ONCHANGED.sub(_add_on_submitted, content)

    # 4. Wrap DataTable in empty-state conditional
    if "pageItems.isEmpty" not in content:
        empty_widget = (
            "pageItems.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(32), "
            "child: Column(mainAxisSize: MainAxisSize.min, children: ["
            "Icon(Icons.inbox, size: 40, color: Color(0xFFD9E2EF)), "
            "SizedBox(height: 8), "
            "Text('\u041d\u0435\u0442 \u0434\u0430\u043d\u043d\u044b\u0445', "
            "style: TextStyle(color: Color(0xFF868686), fontSize: 13))])) "
            ": SingleChildScrollView(child: DataTable("
        )
        new_content = DATATABLE_WRAP.sub(
            "child: " + empty_widget,
            content,
            count=1,
        )
        if new_content != content:
            stats["empty_state"] += 1
            content = new_content
            # Close the ternary by adding one more ) at the end of DataTable block.
            new_content = CLOSING_PATTERN.sub("toList()))))),", content)
            if new_content != content:
                content = new_content

    if content != original:
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)

    return stats


def main():
    total = {"commas": 0, "tooltips": 0, "empty_state": 0, "on_submitted": 0}
    for fn in FILES:
        path = os.path.join(PAGES_DIR, fn)
        if not os.path.exists(path):
            print(f"MISS: {fn}")
            continue
        stats = fix_file(path)
        print(f"  {fn}: commas={stats['commas']}, tooltips={stats['tooltips']}, empty_state={stats['empty_state']}, on_submitted={stats['on_submitted']}")
        for k in total:
            total[k] += stats[k]
    print(f"TOTAL: commas={total['commas']}, tooltips={total['tooltips']}, empty_state={total['empty_state']}, on_submitted={total['on_submitted']}")


if __name__ == "__main__":
    main()
