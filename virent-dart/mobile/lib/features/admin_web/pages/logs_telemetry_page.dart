import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class LogsTelemetryPage extends ConsumerWidget {
  const LogsTelemetryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(logsTelemetryProvider);

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
              const Text('Логи Телеметрии', style: TextStyle(fontSize: 24)),
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
              OutlinedButton(onPressed: () {}, child: const Text('Конкретный день ▼')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () {}, child: const Text('Промежуток времени ▼')),
              const SizedBox(width: 8),
              ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.warning, size: 16), label: const Text('В тревоге'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white)),
              const SizedBox(width: 8),
              SizedBox(
                width: 150,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ID самоката',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 150,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ID заказа',
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
                      DataColumn(label: Text('Id')),
                      DataColumn(label: Text('CarId')),
                      DataColumn(label: Text('Gosnomer')),
                      DataColumn(label: Text('remainingMileage')),
                      DataColumn(label: Text('EcuErrCode')),
                      DataColumn(label: Text('EcuErrType')),
                      DataColumn(label: Text('Order.orderId')),
                      DataColumn(label: Icon(Icons.wifi)),
                      DataColumn(label: Icon(Icons.battery_std)),
                      DataColumn(label: Icon(Icons.lock)),
                      DataColumn(label: Icon(Icons.sensors)),
                      DataColumn(label: Text('Bat (%)')),
                      DataColumn(label: Text('Speed')),
                      DataColumn(label: Text('Sat (%)')),
                      DataColumn(label: Text('Int')),
                      DataColumn(label: Text('Volt')),
                      DataColumn(label: Text('EventTime')),
                      DataColumn(label: Text('ServerTime')),
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

  DataRow_buildItemRow(Map<String, dynamic> item) {
    final id = (item['id'] ?? '').toString();
    final carId = (item['carId'] ?? '').toString();
    final gos = (item['gosnomer'] ?? '').toString();
    final rem = (item['remaining_mileage'] ?? '').toString();
    final errCode = (item['ecu_error_code'] ?? '').toString();
    final errType = (item['ecu_error_type'] ?? '').toString();
    final w1 = item['has_wifi'] == true || item['has_wifi'] == 1 || item['has_wifi'] == '1' || item['has_wifi'] == 'true';
    final w2 = item['has_battery'] == true || item['has_battery'] == 1 || item['has_battery'] == '1' || item['has_battery'] == 'true';
    final w3 = item['has_lock'] == true || item['has_lock'] == 1 || item['has_lock'] == '1' || item['has_lock'] == 'true';
    final w4 = item['has_sensors'] == true || item['has_sensors'] == 1 || item['has_sensors'] == '1' || item['has_sensors'] == 'true';
    final bat = (item['battery_level'] ?? '').toString();
    final rpm = (item['current_speed'] ?? '').toString();
    final sat1 = (item['satellite_count'] ?? '').toString();
    final sat2 = (item['satellite_info'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(id, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(carId, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(gos, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(rem)),
      DataCell(Text(errCode)),
      DataCell(Text(errType)),
      const DataCell(Text('')),
      DataCell(Icon(w1 ? Icons.check_box : Icons.check_box_outline_blank, color: w1 ? Colors.green : Colors.red)),
      DataCell(Icon(w2 ? Icons.check_box : Icons.check_box_outline_blank, color: w2 ? Colors.green : Colors.red)),
      DataCell(Icon(w3 ? Icons.check_box : Icons.check_box_outline_blank, color: w3 ? Colors.green : Colors.red)),
      DataCell(Icon(w4 ? Icons.check_box : Icons.check_box_outline_blank, color: w4 ? Colors.green : Colors.red)),
      DataCell(Text(bat)),
      DataCell(Text(rpm)),
      DataCell(Text(sat1)),
      DataCell(Text(sat2)),
      const DataCell(Text('4 V')),
      const DataCell(Text('19 июн 2026, 14:03:07')),
      const DataCell(Text('19 июн 2026, 14:03:09')),
      DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр'))),
    ]);
  
    );
  ),
);
  }
}