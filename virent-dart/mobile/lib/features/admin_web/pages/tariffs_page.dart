import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class TariffsPage extends ConsumerWidget {
  const TariffsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Тарифы',
      provider: tariffsListProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      createButton: ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.add, size:16),label:const Text("Добавить тариф"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground)),
      columns: const [
        DataColumn(label: Text('Название в админке')),
        DataColumn(label: Text('Название в мобильном приложении')),
        DataColumn(label: Text('Hold')),
      ],
      buildRow: (item) {
        final name_admin = (item['admin_name'] ?? item['name_admin'] ?? item['name'] ?? '-').toString();
        final name_app = (item['app_name'] ?? item['name_app'] ?? item['display_name'] ?? '-').toString();
        final hold = (item['hold'] ?? item['hold_amount'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(name_admin)),
          DataCell(Text(name_app)),
          DataCell(Text(hold)),
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

final _tariffsPageSearchProvider = StateProvider<String>((ref) => '');
