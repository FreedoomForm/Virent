import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class PushHistoryPage extends ConsumerWidget {
  const PushHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'История Push',
      provider: pushHistoryProvider,
      searchProvider: _pushSearchProvider,
      searchMatcher: (p, query) {
        final id = (p['id'] ?? '').toString().toLowerCase();
        final text = (p['text'] ?? p['body'] ?? '').toString().toLowerCase();
        final client = (p['client_id'] ?? '').toString().toLowerCase();
        return id.contains(query) || text.contains(query) || client.contains(query);
      },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Client')),
        DataColumn(label: Text('Text')),
        DataColumn(label: Text('Is read')),
        DataColumn(label: Text('Deleted')),
        DataColumn(label: Text('Created')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (p) {
        String _s(String key) => (p[key] ?? '-').toString();
        bool _b(String key) {
          final v = p[key];
          if (v == null) return false;
          if (v is bool) return v;
          return v.toString().toLowerCase() == '1' || v.toString().toLowerCase() == 'true';
        }
        return DataRow(cells: [
          DataCell(Text(_s('id'))),
          DataCell(Text(_s('client_id'), style: adminLinkStyle)),
          DataCell(Text(_s('text') == '-' ? _s('body') : _s('text'))),
          DataCell(Icon(_b('is_read') ? Icons.check : Icons.close, color: _b('is_read') ? Colors.green : Colors.red)),
          DataCell(Text(_b('deleted') ? 'Да' : 'Нет')),
          DataCell(Text(_s('created_at') == '-' ? _s('created') : _s('created_at'))),
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

final _pushSearchProvider = StateProvider<String>((ref) => '');
