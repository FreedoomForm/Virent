import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class LogsScooterChangesPage extends ConsumerWidget {
  const LogsScooterChangesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Логи Изменений Самокатов',
      provider: logsScooterChangesProvider,
      searchProvider: _scooterChangesSearchProvider,
      filters: Row(
        children: [
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'Номер'),
            ),
          ),
        ],
      ),
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
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(_s('id'))),
          DataCell(Text(_s('scooter_number'), style: adminLinkStyle)),
          DataCell(Text(_s('current_order_id'), style: adminLinkStyle)),
          DataCell(Text(_s('model_id'), style: adminLinkStyle)),
          DataCell(Text(_s('online'))),
          const DataCell(Text('')),
          DataCell(Text(_s('company_id'), style: adminLinkStyle)),
          DataCell(Text(_s('changed_by'))),
          DataCell(Text(_s('geozones'))),
          DataCell(Text(_s('updated_at'))),
          DataCell(Text(_s('created_at'))),
          DataCell(Text(_s('flespi_id'))),
          DataCell(Text(_s('imei'))),
          DataCell(Text(_s('last_order_finished_at'))),
          DataCell(Text(_s('description'))),
        ]);
      },
    );
  }
}

final _scooterChangesSearchProvider = StateProvider<String>((ref) => '');
