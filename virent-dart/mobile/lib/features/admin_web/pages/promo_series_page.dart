import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class PromoSeriesPage extends ConsumerWidget {
  const PromoSeriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Серии Промокодов',
      provider: promoSeriesProvider,
      searchProvider: _seriesSearchProvider,
      searchMatcher: (s, query) {
        final id = (s['id'] ?? '').toString().toLowerCase();
        final name = (s['name'] ?? s['title'] ?? '').toString().toLowerCase();
        return id.contains(query) || name.contains(query);
      },
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Название')),
        DataColumn(label: Text('Активна')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (s) {
        String _s(String key) => (s[key] ?? '-').toString();
        bool _b(String key) {
          final v = s[key];
          if (v == null) return false;
          if (v is bool) return v;
          return v.toString().toLowerCase() == '1' || v.toString().toLowerCase() == 'true';
        }
        return DataRow(cells: [
          DataCell(Text(_s('id'))),
          DataCell(Text(_s('name') == '-' ? _s('title') : _s('name'))),
          DataCell(Icon(_b('active') ? Icons.check : Icons.close, color: _b('active') ? Colors.green : Colors.red)),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить')),
            ],
          )),
        ]);
      },
    );
  }
}

final _seriesSearchProvider = StateProvider<String>((ref) => '');
