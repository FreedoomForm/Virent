import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class PromoSeriesPage extends ConsumerWidget {
  const PromoSeriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Серии Промокодов',
      provider: promoSeriesProvider,
      searchProvider: _seriesSearchProvider,
      searchMatcher: (s, query) {
        final name = (s['name'] ?? s['title'] ?? '').toString().toLowerCase();
        final prefix = (s['prefix'] ?? '').toString().toLowerCase();
        return name.contains(query) || prefix.contains(query);
      },
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить серию промокодов',
          fields: const [
            AdminField(key: 'name', label: 'Название'),
            AdminField(key: 'prefix', label: 'Префикс'),
            AdminField(key: 'count', label: 'Количество', initial: '10'),
            AdminField(key: 'discount', label: 'Скидка'),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/promo-series',
              values,
              promoSeriesProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить Серия промокодов'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Название')),
        DataColumn(label: Text('Префикс')),
        DataColumn(label: Text('Количество')),
        DataColumn(label: Text('Использовано')),
        DataColumn(label: Text('Скидка')),
      ],
      buildRow: (s) {
        final id = (s['id'] ?? '-').toString();
        final name = (s['name'] ?? s['title'] ?? '-').toString();
        final prefix = (s['prefix'] ?? '-').toString();
        final count = (s['count'] ?? s['total'] ?? '-').toString();
        final used = (s['used'] ?? s['used_count'] ?? 0).toString();
        final discount = (s['discount'] ?? s['bonus'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name, style: adminLinkStyle)),
          DataCell(Text(prefix)),
          DataCell(Text(count)),
          DataCell(Text(used)),
          DataCell(Text(discount)),
        ]);
      },
    );
  }
}

final _seriesSearchProvider = StateProvider<String>((ref) => '');
