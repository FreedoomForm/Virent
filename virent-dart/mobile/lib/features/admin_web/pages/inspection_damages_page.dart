import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_table_page.dart';

class InspectionDamagesPage extends ConsumerWidget {
  const InspectionDamagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Damages',
      provider: inspectionDamagesProvider,
      searchProvider: _damagesSearchProvider,
      filters: Row(
        children: [
          SizedBox(
            width: 120,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'Самокат'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'Номер'),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Конкретный день ▼'),
          const SizedBox(width: 16),
          const Text('Промежуток времени ▼'),
          const SizedBox(width: 16),
          OutlinedButton(onPressed: () => showAdminSnack(context, 'Группировка включена'), child: const Text('Группировать')),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: () => showAdminSnack(context, 'Фильтр «Фото при начале» применён'), child: const Text('Фото при начале')),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: () => showAdminSnack(context, 'Фильтр «Фото при завершении» применён'), child: const Text('Фото при завершении', style: TextStyle(color: Colors.orange))),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(inspectionDamagesProvider);
              showAdminSnack(context, 'Фильтры сброшены');
            },
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Очистить фильтры'),
            style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
          ),
        ],
      ),
      columns: const [
        DataColumn(label: Text('Path')),
        DataColumn(label: Text('Car')),
        DataColumn(label: Text('Order')),
        DataColumn(label: Text('Type')),
      ],
      buildRow: (item) {
        String _s(String key, [String fallback = '-']) => (item[key] ?? fallback).toString();
        return DataRow(cells: [
          DataCell(Container(
            width: 80,
            height: 80,
            color: Colors.grey.shade300,
            child: const Icon(Icons.image, color: Colors.grey),
          )),
          DataCell(Text(_s('car'), style: adminLinkStyle)),
          DataCell(Text(_s('order'), style: adminLinkStyle)),
          DataCell(Text(_s('type', 'Завершение'))),
        ]);
      },
    );
  }
}

final _damagesSearchProvider = StateProvider<String>((ref) => '');
