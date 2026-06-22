import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class SelfiesPage extends ConsumerWidget {
  const SelfiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Селфи',
      provider: selfiesListProvider,
      searchProvider: _selfiesSearchProvider,
      filters: Row(
        children: [
          OutlinedButton(onPressed: () => showAdminSnack(context, 'Фильтр «Да» применён'), child: const Text('Да', style: TextStyle(color: Colors.green))),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: () => showAdminSnack(context, 'Фильтр «Нет» применён'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('Нет', style: TextStyle(color: Colors.white))),
          const SizedBox(width: 16),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'ID клиента'),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(selfiesListProvider);
              showAdminSnack(context, 'Фильтры сброшены');
            },
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Очистить фильтры'),
            style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
          ),
        ],
      ),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Фото')),
        DataColumn(label: Text('Проверено')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        bool _b(String key) {
          final v = item[key];
          if (v == null) return false;
          if (v is bool) return v;
          final s = v.toString().toLowerCase();
          return s == '1' || s == 'true' || s == 'yes';
        }
        return DataRow(cells: [
          DataCell(Text(_s('id'), style: adminLinkStyle)),
          DataCell(Container(
            width: 120,
            height: 60,
            color: Colors.grey.shade300,
            child: const Center(child: Icon(Icons.image, color: Colors.grey)),
          )),
          DataCell(Switch(value: _b('verified'), onChanged: (val) {})),
        ]);
      },
    );
  }
}

final _selfiesSearchProvider = StateProvider<String>((ref) => '');
