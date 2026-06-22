import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class LogsClientChangesPage extends ConsumerWidget {
  const LogsClientChangesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Entries',
      provider: logsClientChangesProvider,
      searchProvider: _clientChangesSearchProvider,
      filters: Row(
        children: [
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'ClientID'),
            ),
          ),
        ],
      ),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('ID клиента')),
        DataColumn(label: Text('Доступные тарифы')),
        DataColumn(label: Text('Токен')),
        DataColumn(label: Text('Бонусы')),
        DataColumn(label: Text('Группы')),
        DataColumn(label: Text('Активный')),
        DataColumn(label: Text('Заблокирован')),
        DataColumn(label: Text('Удален')),
        DataColumn(label: Text('Новый')),
        DataColumn(label: Text('Время создания лога')),
      ],
      buildRow: (item) {
        String _s(String key, [String fallback = '-']) => (item[key] ?? fallback).toString();
        final active = _s('active');
        return DataRow(cells: [
          DataCell(Text(_s('id'))),
          DataCell(Text(_s('client_id'), style: adminLinkStyle)),
          DataCell(Text(_s('available_tariffs'))),
          DataCell(Text(_s('token'))),
          DataCell(Text(_s('bonuses'))),
          DataCell(Text(_s('groups', '[]'))),
          DataCell(Text(active.isEmpty || active == '-' ? 'Нет' : active)),
          DataCell(Text(_s('blocked', 'Нет'))),
          DataCell(Text(_s('deleted', 'Нет'))),
          DataCell(Text(_s('is_new', 'Нет'))),
          DataCell(Text(_s('created_at'))),
        ]);
      },
    );
  }
}

final _clientChangesSearchProvider = StateProvider<String>((ref) => '');
