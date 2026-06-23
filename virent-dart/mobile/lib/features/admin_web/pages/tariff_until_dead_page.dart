import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class TariffUntilDeadPage extends ConsumerWidget {
  const TariffUntilDeadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(tariffSubscriptionsProvider);

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
              const Text('Тариф Пока Не Сядет', style: TextStyle(fontSize: 24)),
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
                      DataColumn(label: Text('Название в мобильном приложении')),
                      DataColumn(label: Text('Название в админке')),
                      DataColumn(label: Text('Максимальная длительность в часах')),
                      DataColumn(label: Text('Страховка(Тийны)')),
                      DataColumn(label: Text('стоимость за 1 км(Тийны)')),
                      DataColumn(label: Text('Уровень заряда')),
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

  DataRow _buildItemRow(Map<String, dynamic> item) {
    final appName = (item['app_name'] ?? '').toString();
    final adminName = (item['admin_name'] ?? '').toString();
    final dur = (item['max_duration'] ?? '').toString();
    final ins = (item['insurance'] ?? '').toString();
    final cost = (item['cost_per_km'] ?? '').toString();
    final charge = (item['charge_levels'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(appName, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(adminName)),
      DataCell(Text(dur)),
      DataCell(Text(ins)),
      DataCell(Text(cost)),
      DataCell(Text(charge)),
      DataCell(Row(
        children: [
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр')),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.map, size: 14), label: const Text('Геозоны завершения')),
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