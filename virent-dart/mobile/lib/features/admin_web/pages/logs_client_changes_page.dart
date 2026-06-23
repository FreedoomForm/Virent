import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class LogsClientChangesPage extends ConsumerWidget {
  const LogsClientChangesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(logsClientChangesProvider);

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
                    child: Text('Показано 1 до 20 из 10,000 совпадений', style: TextStyle(color: Colors.grey)),
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
          Row(
            children: [
              SizedBox(
                width: 150,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ClientID',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
              elevation: 0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('ID клиента')),
                      DataColumn(label: Text('Доступные тарифы')),
                      DataColumn(label: Text('Токен')),
                      DataColumn(label: Text('Бонусы')),
                      DataColumn(label: Text('Группы')),
                      DataColumn(label: Text('Активный')),
                      DataColumn(label: Text('Заблокирован')),
                      DataColumn(label: Text('Удален')),
                      DataColumn(label: Text('Новый')),
                      DataColumn(label: Text('Время создания лога')),
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

  DataRow _buildItemRow(Map<String, dynamic> item) {
    final id = (item['id'] ?? '').toString();
    final clientId = (item['client_id'] ?? '').toString();
    final tariffs = (item['available_tariffs'] ?? '').toString();
    final token = (item['token'] ?? '').toString();
    final bonus = (item['bonus'] ?? '').toString();
    final act = (item['is_active'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(id)),
      DataCell(Text(clientId, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(tariffs)),
      DataCell(Text(token)),
      DataCell(Text(bonus)),
      const DataCell(Text('[]')),
      DataCell(Text(act)),
      const DataCell(Text('Нет')),
      const DataCell(Text('Нет')),
      const DataCell(Text('Нет')),
      const DataCell(Text('19 июн 2026, 12:06')),
    ]);
  
  }
      ),
    ),
  );
}