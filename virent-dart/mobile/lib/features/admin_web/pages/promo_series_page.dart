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
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      createButton: ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.add, size:16),label:const Text("Добавить серию"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground)),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Prefix')),
        DataColumn(label: Text('Bonus')),
        DataColumn(label: Text('Usage limit')),
        DataColumn(label: Text('Is active')),
        DataColumn(label: Text('Expires')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final name = (item['name'] ?? '-').toString();
        final prefix = (item['prefix'] ?? '-').toString();
        final bonus = (item['bonus'] ?? item['amount'] ?? '-').toString();
        final usage_limit = (item['usage_limit'] ?? item['limit'] ?? '-').toString();
        final is_active = (item['is_active'] ?? item['active'] ?? '-').toString();
        final expires = (item['expires'] ?? item['expires_at'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name)),
          DataCell(Text(prefix)),
          DataCell(Text(bonus)),
          DataCell(Text(usage_limit)),
          DataCell(Text(is_active)),
          DataCell(Text(expires)),
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

final _promoSeriesPageSearchProvider = StateProvider<String>((ref) => '');
