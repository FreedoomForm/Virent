import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(alertsListProvider);

    return asyncItems.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: \$e', style: const TextStyle(color: Colors.red))),
      data: (items) => Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Тревоги', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 150,
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Самокат', style: TextStyle(color: Colors.grey, height: 2.2)),
                    ),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  value: 'Типы тревог:',
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Типы тревог:', child: Text('Типы тревог:')),
                  ],
                  onChanged: (val) {},
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDA4453), foregroundColor: Colors.white),
                child: const Text('Открыта'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF37BC9B), foregroundColor: Colors.white),
                child: const Text('Закрыта'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
                child: const Text('Группировать'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Сбросить фильтр'),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                  dataRowMaxHeight: 50,
                  columns: const [
                    DataColumn(label: Text('Icon')),
                    DataColumn(label: Text('scooterId')),
                    DataColumn(label: Text('alertType')),
                    DataColumn(label: Text('time')),
                    DataColumn(label: Text('status')),
                  ],
                  rows: items.isEmpty ? [const DataRow(cells: [DataCell(Center(child: Text("В таблице нет доступных данных", style: TextStyle(color: Colors.grey))))])] : items.map(_buildItemRow).toList()                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  DataRow _buildItemRow(Map<String, dynamic> item) {
    final icon = (item['icon'] ?? '').toString();
    final iconColor = (item['iconColor'] ?? '').toString();
    final sId = (item['sId'] ?? '').toString();
    final type = (item['type'] ?? '').toString();
    final time = (item['created_at'] ?? '').toString();
    final st = (item['status'] ?? '').toString();
    final isClosed} = (item['isClosed}'] ?? '').toString();

    final bgColor = isClosed ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2);
    return DataRow(
      color: MaterialStateProperty.all(bgColor),
      cells: [
        DataCell(Container(
          padding: const EdgeInsets.all(4),
          color: Colors.black,
          child: Icon(icon, color: iconColor, size: 16),
        )),
        DataCell(Text(sId, style: const TextStyle(color: Colors.blue))),
        DataCell(Text(type)),
        DataCell(Text(time)),
        DataCell(Text(st)),
      ],
    );
  
  }
      ),
    ),
  );
}