import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class TariffsSubscriptionsPage extends ConsumerWidget {
  const TariffsSubscriptionsPage({super.key});

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
              const Text('Абонементы', style: TextStyle(fontSize: 24)),
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
            onPressed: () { /* action */ },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Добавить абонемент'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
          ),
          const SizedBox(height: 16),
          // Table mockup
          Expanded(
            ref.watch(tariffSubscriptionsProvider).when(
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
                      DataColumn(label: Text('Tariff')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Overrun price')),
                      DataColumn(label: Text('Cost')),
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

  DataRow _buildRow(String tariff, String desc, String overrun, String cost) {
    return DataRow(cells: [
      DataCell(Text(tariff, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(desc, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(overrun)),
      DataCell(Text(cost)),
      DataCell(Row(
        children: [
          TextButton.icon(onPressed: () { /* action */ }, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр')),
          TextButton.icon(onPressed: () { /* action */ }, icon: const Icon(Icons.map, size: 14), label: const Text('Геозоны завершения')),
          TextButton.icon(onPressed: () { /* action */ }, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
          TextButton.icon(onPressed: () { /* action */ }, icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить')),
        ],
      )),
    ]);
  }

  /// Builds a table row from dynamic data item.
  DataRow _buildRowFromItem(Map<String, dynamic> item) {
    return _buildRow(
      item['tariff']?.toString() ?? '',
      item['desc']?.toString() ?? '',
      item['overrun']?.toString() ?? '',
      item['cost']?.toString() ?? '',
    );
  }

}
