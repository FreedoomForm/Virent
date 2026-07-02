import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Поддержка — Тикеты',
      provider: supportTicketsProvider,
      searchProvider: _ticketSearchProvider,
      searchMatcher: (t, query) {
        final id = (t['id'] ?? '').toString().toLowerCase();
        final subject = (t['subject'] ?? t['title'] ?? t['theme'] ?? '').toString().toLowerCase();
        final user = (t['user_id'] ?? t['user'] ?? t['client_id'] ?? '').toString().toLowerCase();
        return id.contains(query) || subject.contains(query) || user.contains(query);
      },
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Тема')),
        DataColumn(label: Text('Пользователь')),
        DataColumn(label: Text('Создан')),
        DataColumn(label: Text('Статус')),
      ],
      buildRow: (t) {
        final id = (t['id'] ?? '-').toString();
        final subject = (t['subject'] ?? t['title'] ?? t['theme'] ?? '-').toString();
        final user = (t['user_id'] ?? t['user'] ?? t['client_id'] ?? t['client'] ?? '-').toString();
        final created = (t['created_at'] ?? t['created'] ?? t['timestamp'] ?? '-').toString();
        final status = (t['status'] ?? t['state'] ?? '-').toString();
        final isOpen = status.toLowerCase() == 'open' || status.toLowerCase() == 'открыт';
        final statusColor = isOpen ? Colors.orange : Colors.green;
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(subject)),
          DataCell(Text(user, style: adminLinkStyle)),
          DataCell(Text(created)),
          DataCell(Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold))),
        ]);
      });
  }
}

final _ticketSearchProvider = StateProvider<String>((ref) => '');
