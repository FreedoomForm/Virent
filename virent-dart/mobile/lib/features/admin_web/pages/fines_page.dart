import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class FinesPage extends ConsumerWidget {
  const FinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Штрафы',
      provider: finesListProvider,
      searchProvider: _finesSearchProvider,
      searchMatcher: (f, query) {
        final id = (f['id'] ?? '').toString().toLowerCase();
        final cid = (f['client_id'] ?? f['clientId'] ?? '').toString().toLowerCase();
        final reason = (f['reason'] ?? f['description'] ?? '').toString().toLowerCase();
        return id.contains(query) || cid.contains(query) || reason.contains(query);
      },
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Пользователь')),
        DataColumn(label: Text('Поездка')),
        DataColumn(label: Text('Сумма')),
        DataColumn(label: Text('Причина')),
        DataColumn(label: Text('Дата')),
        DataColumn(label: Text('Статус')),
      ],
      buildRow: (f) {
        final id = (f['id'] ?? '-').toString();
        final user = (f['user_id'] ?? f['client_id'] ?? f['clientId'] ?? '-').toString();
        final trip = (f['trip_id'] ?? f['order_id'] ?? '-').toString();
        final amount = (f['amount'] ?? f['sum'] ?? '-').toString();
        final reason = (f['reason'] ?? f['description'] ?? '-').toString();
        final date = (f['date'] ?? f['created_at'] ?? f['timestamp'] ?? '-').toString();
        final status = (f['status'] ?? f['state'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(user, style: adminLinkStyle)),
          DataCell(Text(trip)),
          DataCell(Text(amount)),
          DataCell(Text(reason)),
          DataCell(Text(date)),
          DataCell(Text(status)),
        ]);
      },
    );
  }
}

final _finesSearchProvider = StateProvider<String>((ref) => '');
