import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class PromoCodesPage extends ConsumerWidget {
  const PromoCodesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(promoCodesProvider);

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
              const Text('Промокоды', style: TextStyle(fontSize: 24)),
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
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Добавить Промокод'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
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
                    columns: const [
                      DataColumn(label: Text('Id')),
                      DataColumn(label: Text('Code')),
                      DataColumn(label: Text('Bonus gift')),
                      DataColumn(label: Text('Usage remains')),
                      DataColumn(label: Text('Promocode group')),
                      DataColumn(label: Text('Group active')),
                      DataColumn(label: Text('Expires')),
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

  DataRow _buildItemRow(Map<String, dynamic> item) {
    final id = (item['id'] ?? '').toString();
    final code = (item['code'] ?? '').toString();
    final bonus = (item['bonus'] ?? '').toString();
    final usage = (item['usage_remains'] ?? '').toString();
    final group = (item['group_name'] ?? '').toString();
    final isActive = item['is_active'] == true || item['is_active'] == 1 || item['is_active'] == '1' || item['is_active'] == 'true';
    final expires = (item['expires_at'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(id, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(code)),
      DataCell(Text(bonus)),
      DataCell(Text(usage)),
      DataCell(Text(group)),
      DataCell(Icon(isActive ? Icons.check_box : Icons.check_box_outline_blank, color: isActive ? Colors.green : Colors.grey)),
      DataCell(Text(expires)),
      DataCell(Row(
        children: [
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить')),
        ],
      )),
    ]);
  
  }
      ),
    ),
  );
}