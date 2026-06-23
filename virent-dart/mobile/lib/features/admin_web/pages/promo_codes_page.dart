import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class PromoCodesPage extends ConsumerWidget {
  const PromoCodesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Промокоды',
      provider: promoCodesProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      createButton: ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.add, size:16),label:const Text("Добавить Промокод"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground)),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Code')),
        DataColumn(label: Text('Bonus gift')),
        DataColumn(label: Text('Usage remains')),
        DataColumn(label: Text('Promocode group')),
        DataColumn(label: Text('Group active')),
        DataColumn(label: Text('Expires')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final code = (item['code'] ?? '-').toString();
        final bonus = (item['bonus_gift'] ?? item['bonus'] ?? item['amount'] ?? '-').toString();
        final usage = (item['usage_remains'] ?? item['usage'] ?? item['usage_count'] ?? '-').toString();
        final group = (item['promocode_group'] ?? item['group'] ?? item['group_name'] ?? '-').toString();
        final is_active = (item['group_active'] ?? item['is_active'] ?? item['active'] ?? '-').toString();
        final expires = (item['expires'] ?? item['expires_at'] ?? item['expiry'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(code)),
          DataCell(Text(bonus)),
          DataCell(Text(usage)),
          DataCell(Text(group)),
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

final _promoCodesPageSearchProvider = StateProvider<String>((ref) => '');
