import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class TripsPage extends ConsumerWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Поездки',
      provider: adminTripsProvider,
      searchProvider: _tripSearchProvider,
      searchMatcher: (t, query) {
        final id = (t['id'] ?? '').toString().toLowerCase();
        final user = (t['user_id'] ?? t['user'] ?? t['client_id'] ?? '').toString().toLowerCase();
        final scooter = (t['scooter_id'] ?? t['scooter'] ?? '').toString().toLowerCase();
        return id.contains(query) || user.contains(query) || scooter.contains(query);
      },
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Пользователь')),
        DataColumn(label: Text('Самокат')),
        DataColumn(label: Text('Начало')),
        DataColumn(label: Text('Конец')),
        DataColumn(label: Text('Стоимость')),
        DataColumn(label: Text('Статус')),
      ],
      buildRow: (t) {
        final id = (t['id'] ?? '-').toString();
        final user = (t['user_id'] ?? t['user'] ?? t['client_id'] ?? t['client'] ?? '-').toString();
        final scooter = (t['scooter_id'] ?? t['scooter'] ?? t['scooter_qr'] ?? '-').toString();
        final start = (t['start_time'] ?? t['started_at'] ?? t['start'] ?? '-').toString();
        final end = (t['end_time'] ?? t['ended_at'] ?? t['end'] ?? '-').toString();
        final cost = (t['cost'] ?? t['amount'] ?? t['price'] ?? '-').toString();
        final status = (t['status'] ?? t['state'] ?? '-').toString();
        final isActive = status.toLowerCase() == 'active' || status.toLowerCase() == 'ongoing';
        final statusColor = isActive ? Colors.green : Colors.blue;
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(user, style: adminLinkStyle)),
          DataCell(Text(scooter)),
          DataCell(Text(start)),
          DataCell(Text(end)),
          DataCell(Text(cost)),
          DataCell(Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold))),
        ]);
      });
  }
}

final _tripSearchProvider = StateProvider<String>((ref) => '');
