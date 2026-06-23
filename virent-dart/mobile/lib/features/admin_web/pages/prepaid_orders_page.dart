import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class PrepaidOrdersPage extends ConsumerWidget {
  const PrepaidOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Предоплаченные Заказы',
      provider: prepaidOrdersProvider,
      searchProvider: _prepaidSearchProvider,
      searchMatcher: (o, query) {
        final id = (o['id'] ?? '').toString().toLowerCase();
        final token = (o['redis_token'] ?? o['token'] ?? '').toString().toLowerCase();
        final client = (o['client_id'] ?? '').toString().toLowerCase();
        return id.contains(query) || token.contains(query) || client.contains(query);
      },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Redis token')),
        DataColumn(label: Text('Car')),
        DataColumn(label: Text('Client')),
        DataColumn(label: Text('Company')),
        DataColumn(label: Text('Abonement')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Created')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (o) {
        String _s(String key) => (o[key] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(_s('id'))),
          DataCell(Text(_s('redis_token') == '-' ? _s('token') : _s('redis_token'))),
          DataCell(Text(_s('car_id') == '-' ? _s('car') : _s('car_id'))),
          DataCell(Text(_s('client_id') == '-' ? _s('client') : _s('client_id'), style: adminLinkStyle)),
          DataCell(Text(_s('company_id') == '-' ? _s('company') : _s('company_id'))),
          DataCell(Text(_s('abonement_id') == '-' ? _s('abonement') : _s('abonement_id'))),
          DataCell(Text(_s('amount'))),
          DataCell(Text(_s('status'))),
          DataCell(Text(_s('created_at') == '-' ? _s('created') : _s('created_at'))),
          DataCell(Text(_s('type'))),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить')),
            ],
          )),
        ]);
      },
    );
  }
}

final _prepaidSearchProvider = StateProvider<String>((ref) => '');
