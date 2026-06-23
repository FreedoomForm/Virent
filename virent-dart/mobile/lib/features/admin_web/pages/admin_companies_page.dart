import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class AdminCompaniesPage extends ConsumerWidget {
  const AdminCompaniesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Компании',
      provider: adminCompaniesProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      createButton: ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.add, size:16),label:const Text("Добавить компанию"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground)),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Legal name')),
        DataColumn(label: Text('Inn')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Email')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final name = (item['name'] ?? '-').toString();
        final legal_name = (item['legal_name'] ?? item['legalName'] ?? '-').toString();
        final inn = (item['inn'] ?? '-').toString();
        final phone = (item['phone'] ?? '-').toString();
        final email = (item['email'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name)),
          DataCell(Text(legal_name)),
          DataCell(Text(inn)),
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

final _adminCompaniesPageSearchProvider = StateProvider<String>((ref) => '');
