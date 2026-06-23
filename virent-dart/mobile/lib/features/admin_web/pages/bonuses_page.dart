import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class BonusesPage extends ConsumerWidget {
  const BonusesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Бонусы',
      provider: bonusesListProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      createButton: ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.add, size:16),label:const Text("Добавить бонусы"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground)),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Client')),
        DataColumn(label: Text('Bonus sum')),
        DataColumn(label: Text('Who added')),
        DataColumn(label: Text('Create time')),
        DataColumn(label: Text('Comment')),
        DataColumn(label: Text('Company')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final client = (item['client_name'] ?? item['client'] ?? item['name'] ?? '-').toString();
        final bonus_sum = (item['bonus_sum'] ?? item['amount'] ?? item['sum'] ?? '-').toString();
        final who_added = (item['who_added'] ?? item['admin'] ?? item['created_by'] ?? '-').toString();
        final create_time = (item['create_time'] ?? item['created_at'] ?? item['created'] ?? '-').toString();
        final comment = (item['comment'] ?? '-').toString();
        final company = (item['company'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(client)),
          DataCell(Text(bonus_sum)),
          DataCell(Text(who_added)),
          DataCell(Text(create_time)),
          DataCell(Text(comment)),
          DataCell(Text(company)),
        ]);
      },
    );
  }
}

final _bonusesPageSearchProvider = StateProvider<String>((ref) => '');
