import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class TechniciansPage extends ConsumerWidget {
  const TechniciansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(techniciansListProvider);

    return asyncItems.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: \$e', style: const TextStyle(color: Colors.red))),
      data: (items) => Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Техники', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Показано 1 до 17 из 17 совпадений', style: TextStyle(color: Colors.grey)),
                  )),
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Поиск...',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Добавить техник'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
          ),
          const SizedBox(height: 16),
          // Table mockup
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
              elevation: 0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    dataRowMaxHeight: 60,
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                    columns: const [
                      DataColumn(label: Text('Id')),
                      DataColumn(label: Text('Имя')),
                      DataColumn(label: Text('Логин')),
                      DataColumn(label: Text('Companies')),
                      DataColumn(label: Text('Technick key')),
                      DataColumn(label: Text('Permissions')),
                      DataColumn(label: Text('Admin')),
                      DataColumn(label: Text('Пароль')),
                      DataColumn(label: Text('Действия')),
                    ],
                    rows: items.isEmpty ? [const DataRow(cells: [DataCell(Center(child: Text("В таблице нет доступных данных", style: TextStyle(color: Colors.grey))))])] : items.map(_buildItemRow).toList()                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  DataRow_buildItemRow(Map<String, dynamic> item) {
    final id = (item['id'] ?? '').toString();
    final name = (item['name'] ?? '').toString();
    final login = (item['login'] ?? '').toString();
    final companies = (item['companies'] ?? '').toString();
    final key = (item['tech_key'] ?? '').toString();
    final perms = (item['permissions'] ?? '').toString();
    final admin = (item['is_admin'] ?? '').toString();
    final pass = (item['password'] ?? '').toString();

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
  
    );
  ),
);
  }
}