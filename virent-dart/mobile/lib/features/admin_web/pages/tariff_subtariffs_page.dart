import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class TariffSubtariffsPage extends ConsumerWidget {
  const TariffSubtariffsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Подтарифы',
      provider: tariffsListProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Parent tariff')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final name = (item['name'] ?? '-').toString();
        final parent = (item['parent_tariff'] ?? item['parent'] ?? item['parent_id'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name)),
          DataCell(Text(parent)),
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

final _tariffSubtariffsPageSearchProvider = StateProvider<String>((ref) => '');
