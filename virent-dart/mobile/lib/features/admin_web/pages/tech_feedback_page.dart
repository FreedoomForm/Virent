import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class TechFeedbackPage extends ConsumerWidget {
  const TechFeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(techFeedbackProvider);

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
              const Text('Фидбек', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Показано 1 до 20 из 13,420 совпадений', style: TextStyle(color: Colors.grey)),
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
              _buildFilterInput('Самокат'),
              const SizedBox(width: 8),
              _buildFilterInput('Заказ'),
              const SizedBox(width: 8),
              _buildFilterInput('Клиент'),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
                child: const Text('Проверен'),
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
                      DataColumn(label: Text('id')),
                      DataColumn(label: Text('car_id')),
                      DataColumn(label: Text('client_id')),
                      DataColumn(label: Text('order_id')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('checked')),
                      DataColumn(label: Text('Who checked')),
                      DataColumn(label: Text('created_at')),
                      DataColumn(label: Text('updated_at')),
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

  Widget_buildFilterInput(String label) {
    return SizedBox(
      width: 150,
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label, style: const TextStyle(color: Colors.grey, height: 2.2)),
          ),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
    );
  ),
);
  }

  DataRow _buildItemRow(Map<String, dynamic> item) {
    final id = (item['id'] ?? '').toString();
    final carId = (item['carId'] ?? '').toString();
    final clientId = (item['client_id'] ?? '').toString();
    final orderId = (item['orderId'] ?? '').toString();
    final type = (item['type'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(id)),
      DataCell(Text(carId, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(clientId, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(orderId, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(type)),
      const DataCell(Icon(Icons.check_box_outline_blank, color: Colors.grey)),
      const DataCell(Text('')),
      const DataCell(Text('2026-06-18 21:34:19')),
      const DataCell(Text('2026-06-18 21:34:19')),
      DataCell(Row(
        children: [
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр')),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.check, size: 14), label: const Text('Проверить фидбэк')),
        ],
      )),
    ]);
  
  }
}