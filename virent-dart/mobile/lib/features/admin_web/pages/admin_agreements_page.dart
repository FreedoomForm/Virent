import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class AdminAgreementsPage extends ConsumerWidget {
  const AdminAgreementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Договора',
      provider: adminAgreementsProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Number')),
        DataColumn(label: Text('Company')),
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Status')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final number = (item['number'] ?? item['agreement_number'] ?? '-').toString();
        final company = (item['company'] ?? item['company_id'] ?? item['company_name'] ?? '-').toString();
        final date = (item['date'] ?? item['created_at'] ?? item['agreement_date'] ?? '-').toString();
        final status = (item['status'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(number)),
          DataCell(Text(company)),
          DataCell(Text(date)),
          DataCell(Text(status)),
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

final _adminAgreementsPageSearchProvider = StateProvider<String>((ref) => '');
