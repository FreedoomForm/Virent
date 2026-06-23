import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class AdminFaqPage extends ConsumerWidget {
  const AdminFaqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'FAQ',
      provider: adminFaqProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      createButton: ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.add, size:16),label:const Text("Добавить вопрос"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground)),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Question')),
        DataColumn(label: Text('Answer')),
        DataColumn(label: Text('Order')),
        DataColumn(label: Text('Is active')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final question = (item['question'] ?? '-').toString();
        final answer = (item['answer'] ?? '-').toString();
        final order = (item['order'] ?? item['sort_order'] ?? item['ordering'] ?? '-').toString();
        final is_active = (item['is_active'] ?? item['active'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(question)),
          DataCell(Text(answer)),
          DataCell(Text(order)),
          DataCell(Text(is_active)),
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

final _adminFaqPageSearchProvider = StateProvider<String>((ref) => '');
