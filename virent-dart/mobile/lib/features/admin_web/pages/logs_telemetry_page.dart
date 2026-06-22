import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class LogsTelemetryPage extends ConsumerWidget {
  const LogsTelemetryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Логи Телеметрии',
      provider: logsTelemetryProvider,
      searchProvider: _telemetrySearchProvider,
      filters: Row(
        children: [
          OutlinedButton(onPressed: () => showAdminInfoDialog(context, 'Конкретный день', 'Выберите конкретный день'), child: const Text('Конкретный день ▼')),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: () => showAdminInfoDialog(context, 'Промежуток времени', 'Выберите период'), child: const Text('Промежуток времени ▼')),
          const SizedBox(width: 8),
          ElevatedButton.icon(onPressed: () => showAdminSnack(context, 'Фильтр «В тревоге» применён'), icon: const Icon(Icons.warning, size: 16), label: const Text('В тревоге'), style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground)),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'ID самоката'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'ID заказа'),
            ),
          ),
        ],
      ),
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
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        bool _b(String key) {
          final v = item[key];
          if (v == null) return false;
          if (v is bool) return v;
          final s = v.toString().toLowerCase();
          return s == '1' || s == 'true' || s == 'yes';
        }
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(id, style: adminLinkStyle)),
          DataCell(Text(_s('car_id'), style: adminLinkStyle)),
          DataCell(Text(_s('gosnomer'), style: adminLinkStyle)),
          DataCell(Text(_s('remaining_mileage'))),
          DataCell(Text(_s('ecu_err_code'))),
          DataCell(Text(_s('ecu_err_type'))),
          DataCell(Text(_s('order_id'))),
          DataCell(Icon(_b('wifi') ? Icons.check_box : Icons.check_box_outline_blank, color: _b('wifi') ? Colors.green : Colors.red)),
          DataCell(Icon(_b('battery_ok') ? Icons.check_box : Icons.check_box_outline_blank, color: _b('battery_ok') ? Colors.green : Colors.red)),
          DataCell(Icon(_b('locked') ? Icons.check_box : Icons.check_box_outline_blank, color: _b('locked') ? Colors.green : Colors.red)),
          DataCell(Icon(_b('sensors') ? Icons.check_box : Icons.check_box_outline_blank, color: _b('sensors') ? Colors.green : Colors.red)),
          DataCell(Text(_s('battery'))),
          DataCell(Text(_s('speed'))),
          DataCell(Text(_s('sat'))),
          DataCell(Text(_s('int'))),
          DataCell(Text(_s('volt'))),
          DataCell(Text(_s('event_time'))),
          DataCell(Text(_s('server_time'))),
          DataCell(TextButton.icon(
            onPressed: () => showAdminViewDialog(
              context,
              title: 'Лог #$id',
              item: item,
            ),
            icon: const Icon(Icons.visibility, size: 14),
            label: const Text('Просмотр'),
          )),
        ]);
      },
    );
  }
}

final _telemetrySearchProvider = StateProvider<String>((ref) => '');
