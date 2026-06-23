import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class TechniciansPage extends ConsumerWidget {
  const TechniciansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Техники',
      provider: techniciansListProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      createButton: ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.add, size:16),label:const Text("Добавить техник"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground)),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Имя')),
        DataColumn(label: Text('Логин')),
        DataColumn(label: Text('Companies')),
        DataColumn(label: Text('Technick key')),
        DataColumn(label: Text('Permissions')),
        DataColumn(label: Text('Admin')),
        DataColumn(label: Text('Пароль')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final name = (item['name'] ?? '-').toString();
        final login = (item['login'] ?? item['email'] ?? '-').toString();
        final companies = (item['companies'] ?? '-').toString();
        final key = (item['technick_key'] ?? item['key'] ?? item['tech_key'] ?? '-').toString();
        final perms = (item['permissions'] ?? item['perms'] ?? '-').toString();
        final admin = (item['admin'] ?? item['is_admin'] ?? '-').toString();
        final pass = (item['password'] ?? item['pass'] ?? item['pass_hash'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name)),
          DataCell(Text(login)),
          DataCell(Text(companies)),
          DataCell(Text(key)),
          DataCell(Text(perms)),
          DataCell(Text(admin)),
          DataCell(Text(pass)),
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

final _techniciansPageSearchProvider = StateProvider<String>((ref) => '');
