import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class ChatLogsPage extends ConsumerWidget {
  const ChatLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Сообщения',
      provider: chatLogsProvider,
      showMatchCount: false,
      filters: Row(
        children: [
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'ID клиента'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'Выберите даты'),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => showAdminSnack(context, 'Поиск выполнен'),
            style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
            child: const Text('Поиск по тексту'),
          ),
        ],
      ),
      columns: const [
        DataColumn(label: Text('client_id')),
        DataColumn(label: Text('message')),
        DataColumn(label: Text('image')),
        DataColumn(label: Text('Answer')),
        DataColumn(label: Text('timestamp')),
        DataColumn(label: Text('Location')),
        DataColumn(label: Text('read_by_admin')),
        DataColumn(label: Text('read_date')),
        DataColumn(label: Text('Управление')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final hasImage = (item['image'] ?? '').toString().isNotEmpty;
        final clientId = _s('client_id');
        return DataRow(cells: [
          DataCell(Text(clientId, style: adminLinkStyle)),
          DataCell(hasImage ? const SizedBox() : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.amber,
            child: const Text('Прочитать новое сообщение', style: TextStyle(color: Colors.white, fontSize: 12)),
          )),
          DataCell(hasImage ? const Icon(Icons.image) : const SizedBox()),
          DataCell(Text(_s('answer'))),
          DataCell(Text(_s('timestamp'))),
          DataCell(const Text('посмотреть', style: TextStyle(color: Colors.blue))),
          DataCell(Text(_s('read_by_admin'))),
          DataCell(Text(_s('read_date'))),
          DataCell(ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
            onPressed: () => showAdminFormDialog(
              context,
              title: 'Написать сообщение клиенту #$clientId',
              fields: const [
                AdminField(key: 'message', label: 'Сообщение', multiline: true),
              ],
              onSubmit: (values) async {
                await ref.read(genericCreateAction)(
                  '/admin/chat-logs',
                  {'client_id': clientId, ...values},
                  chatLogsProvider,
                );
              },
            ),
            child: const Text('Написать сообщение'),
          )),
        ]);
      },
    );
  }
}
