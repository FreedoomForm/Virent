import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class SettingsDriversPage extends ConsumerWidget {
  const SettingsDriversPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
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
                    child: Text('Показано 1 до 4 из 4 совпадений', style: TextStyle(color: Colors.grey)),
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
            onPressed: () { /* action */ },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Добавить entry'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
          ),
          const SizedBox(height: 16),
          Expanded(
            ref.watch(settingsDriversProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Ошибка: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('Нет данных', style: TextStyle(color: Colors.grey)));
                }
                return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300));
              },
            ),
              elevation: 0,
              child: ListView(
                children: [
                  DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                    columns: const [
                      DataColumn(label: Text('Id')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Действия')),
                    ],
                    rows: items.map((item) => _buildRowFromItem(item)).toList(),,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  DataRow _buildRow(String id, String desc, String type) {
    return DataRow(cells: [
      DataCell(Text(id)),
      DataCell(Text(desc)),
      DataCell(Text(type)),
      DataCell(Row(
        children: [
          TextButton.icon(onPressed: () { /* action */ }, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр')),
          TextButton.icon(onPressed: () { /* action */ }, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
          TextButton.icon(onPressed: () { /* action */ }, icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить')),
        ],
      )),
    ]);
  }

  /// Builds a table row from dynamic data item.
  DataRow _buildRowFromItem(Map<String, dynamic> item) {
    return _buildRow(
      item['id']?.toString() ?? '',
      item['desc']?.toString() ?? '',
      item['type']?.toString() ?? '',
    );
  }

}
