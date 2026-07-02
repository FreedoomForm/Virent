# Admin Web Refactor Worklog

## Task ID: FIX-DATATABLE-BATCH4

**Date:** Refactor batch 4 — tariff/tech/settings pages
**Scope:** Convert 12 hardcoded sample-data pages to DataTable + Riverpod provider pattern (mirror of `sms_logs_page.dart`).

### Pages fixed (12)

| # | File | Provider | Title | Columns |
|---|------|----------|-------|---------|
| 1 | `tariff_abonements_page.dart` | `tariffAbonementsProvider` | Абонементы | Tariff, Description, Overrun price, Cost |
| 2 | `tariff_offers_page.dart` | `tariffsListProvider` | Тарифы | Название в админке, Название в приложении, Hold |
| 3 | `tariff_prices_page.dart` | `tariffPricesProvider` | Цены | Наименование, Json, Time unit |
| 4 | `tariff_subscription_page.dart` | `tariffSubscriptionProvider` | Подписочные тарифы | Name, Name in app, Price, Group, Active |
| 5 | `tariff_until_dead_page.dart` | `tariffUntilDeadProvider` | Тариф пока не сядет | Название в приложении, Название в админке, Максимальная длительность, Страховка, Стоимость за 1 км, Уровень заряда |
| 6 | `tarirov_page.dart` | `tarirovProvider` | Тарирование | id, Joan, Volume, Cruising range, Cruising time |
| 7 | `technician_tasks_page.dart` | `techTasksProvider` | Задачи техников | id, Title, Technician, Description, Create by, Create time, Завершен, Finish time |
| 8 | `technicians_page.dart` | `techniciansProvider` | Техники | Id, Имя, Логин |
| 9 | `tech_feedback_page.dart` | `techFeedbackProvider` | Фидбек | id, car_id, client_id, order_id, Type, checked, Who checked, created_at |
| 10 | `models_page.dart` | `modelsProvider` | Модели | Id, Is public, Image, Name |
| 11 | `scooter_groups_page.dart` | `scooterGroupsProvider` | Группы самокатов | id, Description, Trigger equation |
| 12 | `drivers_page.dart` | `driversProvider` | Драйверы | id, Value, Description, Type |

### What was done

For every page:
1. Replaced `ConsumerWidget` with `ConsumerStatefulWidget` + private state class.
2. Added state fields: `_searchController`, `_selectedIds`, `_query`, `_currentPage`, `_pageSize`.
3. Added `dispose()` to free `_searchController`.
4. Wired `ref.watch(<provider>)` and used `async.when(loading/error/data)`.
5. Implemented client-side search filter + pagination (`_pageSize = 20`).
6. Rendered data through `DataTable` with `pageItems.map<DataRow>((i) => _buildRow(context, ref, i)).toList()`.
7. Added `_buildRow(BuildContext context, WidgetRef ref, Map<String, dynamic> item)` helper using `"${item['field'] ?? ''}"` double-quoted interpolation.
8. Per-row checkbox, view / edit / delete actions wired through `showAdminViewDialog` / `showAdminFormDialog` / `showAdminDeleteDialog`.
9. `_buildBulkActionBar` for bulk delete with `showAdminBulkActionDialog`.
10. `_buildPaginationBar` using `min` from `dart:math`.
11. Header row with export (CSV/JSON/XLSX) and filter dialogs from `admin_export.dart` / `admin_dialogs.dart`.
12. `AdminStatusTabsRow` with a single "Всего" badge.
13. Empty-state UI (Icon inbox + "Нет данных") when `pageItems.isEmpty`.

### Imports added (in order)

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_export.dart';
import '../widgets/admin_status_tabs.dart';
import '../widgets/admin_colors.dart';
```

### Providers added to `admin_web_providers.dart`

The following new providers were added (existing pages that still reference the older aliases such as `tariffSubscriptionsProvider`, `techniciansListProvider`, `settingsDriversProvider`, `settingsScooterGroupsProvider`, `scootersListProvider` continue to work unchanged):

| Provider | Endpoint | Notes |
|----------|----------|-------|
| `tariffSubscriptionProvider` | `/admin/tariff-subscriptions` | Singular alias; task-spec name. |
| `tariffUntilDeadProvider` | `/admin/tariff-until-dead` | New endpoint for "Тариф пока не сядет". |
| `tarirovProvider` | `/admin/tarirov` | New endpoint for "Тарирование". |
| `modelsProvider` | `/admin/models` | New endpoint for "Модели". |
| `techniciansProvider` | `/admin/technicians` | Short alias of `techniciansListProvider`. |
| `driversProvider` | `/admin/settings/drivers` | Short alias of `settingsDriversProvider`. |
| `scooterGroupsProvider` | `/admin/settings/scooter-groups` | Short alias of `settingsScooterGroupsProvider`. |

### Critical-rule compliance

- [x] Double-quoted field interpolation: `"${item['field'] ?? ''}"` used everywhere.
- [x] Helper signature: `DataRow _buildRow(BuildContext context, WidgetRef ref, Map<String, dynamic> item)`.
- [x] Imports: `admin_dialogs.dart`, `admin_colors.dart`, `admin_export.dart`, `admin_status_tabs.dart`, `dart:math`.
- [x] `.map<DataRow>()` used for row mapping.
- [x] No duplicate `context` parameter (only one `BuildContext context` per helper signature).
- [x] No trailing commas introduced in single-line widget trees.
- [x] No `const InputDecoration` with an Icon color (the search box `InputDecoration` is non-const because it embeds `Icon(Icons.search, ..., color: adminTextGray)`).
- [x] Braces and parens balanced in every file (verified with `grep -o` counts).
- [x] Provider names in `ref.watch` and `ref.invalidate` match the task spec.

### Verification

`flutter analyze` could not be run (no Flutter SDK in sandbox). Verified manually:

- All 12 files: open/close braces balanced (e.g. 33/33, 31/31, …).
- All 12 files: open/close parens balanced.
- All 12 files: contain exactly one `ConsumerStatefulWidget` + `ConsumerState<T>` pair.
- All 12 files: contain exactly one `_buildRow(BuildContext context, WidgetRef ref` declaration.
- All 12 files: contain exactly one `.map<DataRow>(` call.
- All 12 files: import `dart:math`, `admin_dialogs.dart`, `admin_colors.dart`, `admin_export.dart`, `admin_status_tabs.dart`.
- All 12 files: zero occurrences of `const InputDecoration`.
- All 12 files: titles match task spec (verified via `fontSize: 22` grep).
- All 12 files: `ref.watch(<provider>)` and `ref.invalidate(<provider>)` use the task-specified provider names.
- `admin_web_providers.dart`: braces/parens balanced (64/64, 510/510) after adding the seven new providers.
- `app_layout.dart`: still references the existing class names (`TariffAbonementsPage`, `TariffOffersPage`, `TariffPricesPage`, `TariffsSubscriptionsPage`, `TariffUntilDeadPage`, `TechniciansPage`, `TechnicianTasksPage`, `TechFeedbackPage`, `ScooterGroupsPage`, `DriversPage`, `TarirovPage`, `ModelsPage`) — no class renames were introduced, so navigation still resolves.

### Notes / Pre-existing observations (not introduced by this batch)

- `tariff_subscription_page.dart` and `tariffs_subscriptions_page.dart` both declare `class TariffsSubscriptionsPage`. The former is not imported anywhere in `lib/` (orphan file), so no conflict is triggered at compile time. Both files have been refactored to the same DataTable pattern in their respective batches.
- `models_page.dart` originally watched `scootersListProvider` (incorrect). It now correctly watches `modelsProvider`.
- `tariff_until_dead_page.dart` originally watched `tariffSubscriptionsProvider` (incorrect — that provider belongs to the subscription page). It now correctly watches `tariffUntilDeadProvider`.

### Files modified (13 total)

1. `mobile/lib/features/admin_web/admin_web_providers.dart` (added 7 providers)
2. `mobile/lib/features/admin_web/pages/tariff_abonements_page.dart`
3. `mobile/lib/features/admin_web/pages/tariff_offers_page.dart`
4. `mobile/lib/features/admin_web/pages/tariff_prices_page.dart`
5. `mobile/lib/features/admin_web/pages/tariff_subscription_page.dart`
6. `mobile/lib/features/admin_web/pages/tariff_until_dead_page.dart`
7. `mobile/lib/features/admin_web/pages/tarirov_page.dart`
8. `mobile/lib/features/admin_web/pages/technician_tasks_page.dart`
9. `mobile/lib/features/admin_web/pages/technicians_page.dart`
10. `mobile/lib/features/admin_web/pages/tech_feedback_page.dart`
11. `mobile/lib/features/admin_web/pages/models_page.dart`
12. `mobile/lib/features/admin_web/pages/scooter_groups_page.dart`
13. `mobile/lib/features/admin_web/pages/drivers_page.dart`
