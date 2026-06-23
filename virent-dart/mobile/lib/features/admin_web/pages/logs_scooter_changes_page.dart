import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class LogsScooterChangesPage extends ConsumerWidget {
  const LogsScooterChangesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(logsScooterChangesProvider);

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
              const Text('Логи Изменений Самокатов', style: TextStyle(fontSize: 24)),
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
                    hintText: 'Номер',
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
                      DataColumn(label: Text('Номер самоката')),
                      DataColumn(label: Text('ID текущего заказа')),
                      DataColumn(label: Text('ID модели')),
                      DataColumn(label: Text('Онлайн')),
                      DataColumn(label: Text('columns.elastic_car_change_log.scooter_action')),
                      DataColumn(label: Text('ID компании')),
                      DataColumn(label: Text('Кто внёс изменения')),
                      DataColumn(label: Text('Геозоны')),
                      DataColumn(label: Text('Время обновления')),
                      DataColumn(label: Text('Время создания')),
                      DataColumn(label: Text('Флеспи ID')),
                      DataColumn(label: Text('Imei')),
                      DataColumn(label: Text('Время завершения последнего заказа')),
                      DataColumn(label: Text('Описание')),
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

  DataRow_buildItemRow(Map<String, dynamic> item) {
    final id = (item['id'] ?? '').toString();
    final num = (item['gosnomer'] ?? '').toString();
    final currOrder = (item['current_order_id'] ?? '').toString();
    final model = (item['model_id'] ?? '').toString();
    final online = (item['is_online'] ?? '').toString();
    final compId = (item['company_id'] ?? '').toString();
    final user = (item['updated_by'] ?? '').toString();
    final geo = (item['geozones'] ?? '').toString();
    final upd = (item['updated_at'] ?? '').toString();
    final crt = (item['created_at'] ?? '').toString();
    final flespi = (item['flespi_id'] ?? '').toString();
    final imei = (item['imei'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(id)),
      DataCell(Text(num, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(currOrder, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(model, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(online)),
      const DataCell(Text('')),
      DataCell(Text(compId, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(user)),
      DataCell(Text(geo)),
      DataCell(Text(upd)),
      DataCell(Text(crt)),
      DataCell(Text(flespi)),
      DataCell(Text(imei)),
      const DataCell(Text('16 июн 2026, 20:43:47')),
      const DataCell(Text('')),
    ]);
  
    );
  ),
);
  }
}