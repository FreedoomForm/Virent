// admin_table_page.dart — Reusable scaffold for admin data-table pages.
//
// Eliminates ~80 lines of boilerplate per page. Each page only provides:
//   * title, provider, columns, and a row-builder
//   * optional search, create button, filters, and header actions
//
// The widget preserves full customisability — pages that need unique
// layouts can still build their own, but 45+ of the 52 existing pages
// can switch to this base with zero visual change.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Shared admin styling constants ───────────────────────────────────────

/// Primary action colour used across all admin pages.
const Color adminPageBg = Color(0xFFF1F4F8);
const Color adminPrimaryColor = Color(0xFF7C69EF);

/// Foreground colour for buttons using [adminPrimaryColor].
const Color adminPrimaryForeground = Colors.white;

/// Default card shape for admin table cards.
final ShapeBorder adminCardShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(8),
  side: BorderSide(color: Color(0xFFD9E2EF)),
);

/// Heading row colour for DataTable widgets.
final WidgetStateProperty<Color> adminTableHeadingColor =
    WidgetStateProperty.all(Color(0xFFF1F4F8));

/// Text style for ID / link-like cells in admin tables.
const TextStyle adminLinkStyle = TextStyle(color: Colors.blue);

/// Common InputDecoration for search TextFields.
InputDecoration adminSearchDecoration({String label = 'Поиск...'}) {
  return InputDecoration(
    labelText: label,
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}

/// Common InputDecoration for filter TextFields.
InputDecoration adminFilterDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}

// ─── AdminTablePage widget ────────────────────────────────────────────────

/// A fully-functional admin list page scaffold.
///
/// Provides:
///   * Title row with match count
///   * Optional search field with client-side filtering
///   * Optional "Add" button
///   * Optional filters row
///   * Async loading / error / empty states
///   * DataTable inside a scrollable Card
///
/// Pages that need a completely custom layout should NOT use this widget —
/// it is an opt-in convenience, not a mandate.
class AdminTablePage extends ConsumerWidget {
  const AdminTablePage({
    super.key,
    required this.title,
    required this.provider,
    required this.columns,
    required this.buildRow,
    this.searchProvider,
    this.searchMatcher,
    this.createButton,
    this.filters,
    this.headerActions,
    this.showMatchCount = true,
  });

  /// Page title displayed at the top.
  final String title;

  /// Riverpod provider that fetches the list of items.
  final AutoDisposeFutureProvider<List<Map<String, dynamic>>> provider;

  /// DataTable column definitions.
  final List<DataColumn> columns;

  /// Builds a [DataRow] from a single item map.
  final DataRow Function(Map<String, dynamic> item) buildRow;

  /// Optional [StateProvider] for search text. When provided, a search
  /// TextField is shown and client-side filtering is enabled.
  final StateProvider<String>? searchProvider;

  /// Custom search matcher. When null, the default matcher checks all string
  /// values in the item map with `.toLowerCase().contains(query)`.
  final bool Function(Map<String, dynamic> item, String query)? searchMatcher;

  /// Optional widget placed between the title row and the table.
  /// Typically an `ElevatedButton.icon` for "Добавить …".
  final Widget? createButton;

  /// Optional filter row widget placed below the create button.
  final Widget? filters;

  /// Optional widgets appended to the title row (e.g., extra action buttons).
  final List<Widget>? headerActions;

  /// Whether to show the "Показано N совпадений" counter.
  final bool showMatchCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(provider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ──────────────────────────────────────────────
          _buildTitleRow(asyncItems, ref),
          const SizedBox(height: 16),

          // ── Create button ──────────────────────────────────────────
          if (createButton != null) ...[
            createButton!,
            const SizedBox(height: 16),
          ],

          // ── Filters row ────────────────────────────────────────────
          if (filters != null) ...[
            filters!,
            const SizedBox(height: 16),
          ],

          // ── Data table ─────────────────────────────────────────────
          Expanded(
            child: Card(
              shape: adminCardShape,
              elevation: 0,
              child: asyncItems.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Ошибка загрузки: $e',
                      style: const TextStyle(color: Colors.red)),
                ),
                data: (items) => _buildTable(items, ref),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(
      AsyncValue<List<Map<String, dynamic>>> asyncItems, WidgetRef ref) {
    final children = <Widget>[
      Text(title, style: const TextStyle(fontSize: 24)),
    ];

    if (showMatchCount) {
      children.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Показано ${asyncItems.maybeWhen(data: (d) => d.length, orElse: () => 0)} совпадений',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    } else {
      children.add(const Expanded(child: SizedBox()));
    }

    if (headerActions != null) {
      children.addAll(headerActions!);
    }

    if (searchProvider != null) {
      children.add(
        SizedBox(
          width: 200,
          child: TextField(
            decoration: adminSearchDecoration(),
            onChanged: (v) =>
                ref.read(searchProvider!.notifier).state = v,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children,
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> items, WidgetRef ref) {
    // Apply search filter if search provider is configured
    List<Map<String, dynamic>> filtered = items;
    if (searchProvider != null) {
      final query = ref.watch(searchProvider!).toLowerCase();
      if (query.isNotEmpty) {
        filtered = items.where((item) {
          if (searchMatcher != null) {
            return searchMatcher!(item, query);
          }
          return _defaultSearchMatcher(item, query);
        }).toList();
      }
    }

    if (filtered.isEmpty) {
      return const Center(child: Text('Совпадений не найдено'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: adminTableHeadingColor,
          dataRowMaxHeight: 60,
          columns: columns,
          rows: filtered.map(buildRow).toList(),
        ),
      ),
    );
  }

  /// Default search: check all string-convertible values in the map.
  static bool _defaultSearchMatcher(Map<String, dynamic> item, String query) {
    for (final value in item.values) {
      if (value != null && value.toString().toLowerCase().contains(query)) {
        return true;
      }
    }
    return false;
  }
}

/// Family of search providers keyed by page name.
///
/// Usage:
/// ```dart
/// final mySearchProvider = adminSearchFamily('my_page');
/// ```
final adminSearchFamily = StateProvider.family<String, String>((ref, _) => '');

/// Convenience: creates a [StateProvider] for page-local search.
/// Each page still owns its own provider instance (preserving existing code).
StateProvider<String> adminSearchProvider(String pageId) =>
    StateProvider<String>((ref) => '');
