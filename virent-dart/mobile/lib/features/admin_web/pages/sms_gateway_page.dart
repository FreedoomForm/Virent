import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class SmsGatewayPage extends ConsumerWidget {
  const SmsGatewayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'SMS Шлюз',
      provider: smsLogsProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Provider')),
        DataColumn(label: Text('Status')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final provider = (item['provider'] ?? '-').toString();
        final status = (item['status'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(provider)),
          DataCell(Text(status)),
          DataCell(TextButton.icon(onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), icon: const Icon(Icons.edit, size: 12, color: Color(0xFF467FD0)), label: const Text('Редактировать', style: TextStyle(fontSize: 10, color: Color(0xFF467FD0))))),
        ]);
      },
    );
  }
}

final _smsGatewayPageSearchProvider = StateProvider<String>((ref) => '');
