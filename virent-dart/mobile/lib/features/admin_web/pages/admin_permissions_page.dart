import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class AdminPermissionsPage extends ConsumerWidget {
  const AdminPermissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Разрешения',
      provider: adminPermissionsProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Key')),
        DataColumn(label: Text('Description')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final name = (item['name'] ?? '-').toString();
        final key = (item['key'] ?? item['permission_key'] ?? '-').toString();
        final desc = (item['description'] ?? item['desc'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name)),
          DataCell(Text(key)),
          DataCell(Text(desc)),
          DataCell(Row(
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

final _adminPermissionsPageSearchProvider = StateProvider<String>((ref) => '');
