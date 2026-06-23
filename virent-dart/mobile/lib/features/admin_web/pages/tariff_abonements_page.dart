import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class TariffAbonementsPage extends ConsumerWidget {
  const TariffAbonementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Абонементы',
      provider: tariffAbonementsProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Duration')),
        DataColumn(label: Text('Price')),
        DataColumn(label: Text('Is active')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final name = (item['name'] ?? '-').toString();
        final duration = (item['duration'] ?? item['duration_days'] ?? '-').toString();
        final price = (item['price'] ?? '-').toString();
        final is_active = (item['is_active'] ?? item['active'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name)),
          DataCell(Text(duration)),
          DataCell(Text(price)),
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

final _tariffAbonementsPageSearchProvider = StateProvider<String>((ref) => '');
