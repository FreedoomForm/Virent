import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class InspectionDamagesPage extends ConsumerWidget {
  const InspectionDamagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(inspectionDamagesProvider);

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
              const Text('Damages', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Показано 1 до 20 из 297 совпадений', style: TextStyle(color: Colors.grey)),
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
              _buildFilterField('Самокат', width: 120),
              const SizedBox(width: 8),
              _buildFilterField('Номер', width: 120),
              const SizedBox(width: 8),
              const Text('Конкретный день ▼'),
              const SizedBox(width: 16),
              const Text('Промежуток времени ▼'),
              const SizedBox(width: 16),
              OutlinedButton(onPressed: () {}, child: const Text('Группировать')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () {}, child: const Text('Фото при начале')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () {}, child: const Text('Фото при завершении', style: TextStyle(color: Colors.orange))),
              const SizedBox(width: 8),
               ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Очистить фильтры'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 16),
          // Table mockup
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
              elevation: 0,
              child: ListView(
                children: [
                  DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                    dataRowMaxHeight: 100,
                    columns: const [
                      DataColumn(label: Text('Path')),
                      DataColumn(label: Text('Car')),
                      DataColumn(label: Text('Order')),
                      DataColumn(label: Text('Type')),
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

      ),
    );
  );
  Widget _buildFilterField(String hint, {double width = 150}) {
    return SizedBox(
      width: width,
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  DataRow _buildItemRow(Map<String, dynamic> item) {
    final car = (item['car_id'] ?? '').toString();
    final order = (item['order_id'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Container(
        width: 80,
        height: 80,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image, color: Colors.grey),
      )),
      DataCell(Text(car, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(order, style: const TextStyle(color: Colors.blue))),
      const DataCell(Text('Завершение')),
    ]);
  
  }
}