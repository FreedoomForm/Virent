import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class AdminContactsPage extends ConsumerWidget {
  const AdminContactsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(adminContactsProvider);

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
              const Text('Entries', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Показано 1 до 1 из 1 совпадений', style: TextStyle(color: Colors.grey)),
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
            label: const Text('Добавить entry'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
              elevation: 0,
              child: ListView(
                children: [
                  DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                    columns: const [
                      DataColumn(label: Text('City')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Telegram')),
                      DataColumn(label: Text('Whatsapp')),
                      DataColumn(label: Text('Faq')),
                      DataColumn(label: Text('Company')),
                      DataColumn(label: Text('Действия')),
                    ],
                    rows: items.isEmpty ? [const DataRow(cells: [DataCell(Center(child: Text("В таблице нет доступных данных", style: TextStyle(color: Colors.grey))))])] : items.map(_buildItemRow).toList()                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  DataRow_buildItemRow(Map<String, dynamic> item) {
    final city = (item['city'] ?? '').toString();
    final phone = (item['phone'] ?? '').toString();
    final email = (item['email'] ?? '').toString();
    final tg = (item['telegram'] ?? '').toString();
    final wp = (item['whatsapp'] ?? '').toString();
    final faq = (item['faq'] ?? '').toString();
    final comp = (item['company_id'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(city)),
      DataCell(Text(phone)),
      DataCell(Text(email, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(tg)),
      DataCell(Text(wp)),
      DataCell(Text(faq)),
      DataCell(Text(comp)),
      DataCell(Row(
        children: [
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      )),
    ]);
  
    );
  ),
);
  }
}