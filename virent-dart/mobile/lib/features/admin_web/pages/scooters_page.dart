import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class ScootersPage extends ConsumerWidget {
  const ScootersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(scootersListProvider);

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
              const Text('Самокаты', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Показано 1 до 20 из 300 совпадений', style: TextStyle(color: Colors.grey)),
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
            label: const Text('Добавить самокат'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
          ),
          const SizedBox(height: 16),
          // Filters row mockup
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterField('Номер'),
                const SizedBox(width: 8),
                _buildFilterField('Комментарий', width: 200),
                const SizedBox(width: 8),
                _buildFilterField('От (%)', width: 80),
                const SizedBox(width: 8),
                _buildFilterField('До (%)', width: 80),
                const SizedBox(width: 8),
                _buildDropdownBtn('Модель'),
                const SizedBox(width: 8),
                _buildDropdownBtn('Группы'),
                const SizedBox(width: 8),
                _buildDropdownBtn('Компания'),
                const SizedBox(width: 8),
                _buildDropdownBtn('Геозоны'),
              ],
            ),
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
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                    dataRowMaxHeight: 60,
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Gosnomer')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Locks')),
                      DataColumn(label: Text('Battery')),
                      DataColumn(label: Text('Speed')),
                      DataColumn(label: Text('Geozones')),
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

  Widget _buildFilterField(String hint, {double width = 120}) {
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

  Widget _buildDropdownBtn(String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.arrow_drop_down, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7B68EE),
        foregroundColor: Colors.white,
      ),
    );
  }

  DataRow _buildItemRow(Map<String, dynamic> item) {
    final id = (item['id'] ?? '').toString();
    final gosnomer = (item['gosnomer'] ?? '').toString();
    final status = (item['status'] ?? '').toString();
    final battery = (item['battery'] ?? '').toString();
    final speed = (item['speed'] ?? '').toString();
    final geo = (item['geozones'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(id)),
      DataCell(Text(gosnomer, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(status, style: TextStyle(color: status == 'ONLINE' ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
      DataCell(const Icon(Icons.lock, color: Colors.green, size: 16)),
      DataCell(Text(battery)),
      DataCell(Text(speed)),
      DataCell(Text(geo, style: const TextStyle(color: Colors.blue))),
      DataCell(Row(
        children: [
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр')),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
        ],
      )),
    ]);
  
  }
      ),
    ),
  );
}