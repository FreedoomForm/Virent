import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class AdminContactsPage extends ConsumerWidget {
  const AdminContactsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Контакты',
      provider: adminContactsProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Email')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final name = (item['name'] ?? '-').toString();
        final phone = (item['phone'] ?? '-').toString();
        final email = (item['email'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name)),
          DataCell(Text(phone)),
          DataCell(Text(email)),
          DataCell(Row(
            children: [
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр')),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить')),
            ],
          )),
        ]);
      },
    );
  }
}

final _adminContactsPageSearchProvider = StateProvider<String>((ref) => '');
