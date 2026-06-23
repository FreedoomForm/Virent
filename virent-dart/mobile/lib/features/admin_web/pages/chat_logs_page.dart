import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class ChatLogsPage extends ConsumerWidget {
  const ChatLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(chatLogsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Сообщения', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 150,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ID клиента',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 150,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Выберите даты',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
                child: const Text('Поиск по тексту'),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
              elevation: 0,
              child: asyncItems.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
                data: (items) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
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
                      rows: items.map(_buildRow).toList(),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  DataRow _buildRow(Map<String, dynamic> c) {
    final cid = (c['client_id'] ?? c['client'] ?? '-').toString();
    final time = (c['timestamp'] ?? c['created_at'] ?? '-').toString();
    final hasImage = (c['image'] ?? c['has_image'] ?? false) == true || (c['image'] ?? c['has_image'] ?? '') == '1';
    final message = (c['message'] ?? c['text'] ?? '').toString();
    final location = (c['location'] ?? c['geo'] ?? '').toString();
    final readBy = (c['read_by_admin'] ?? c['read'] ?? '').toString();
    final readDate = (c['read_date'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(cid, style: const TextStyle(color: Colors.blue))),
      DataCell(message.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.amber,
              child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 12)),
            )
          : hasImage ? const SizedBox() : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.amber,
              child: const Text('Прочитать новое сообщение', style: TextStyle(color: Colors.white, fontSize: 12)),
            )),
      DataCell(hasImage ? const Icon(Icons.image) : const SizedBox()),
      const DataCell(Text('')),
      DataCell(Text(time)),
      DataCell(location.isNotEmpty ? const Text('посмотреть', style: TextStyle(color: Colors.blue)) : const Text('')),
      DataCell(Text(readBy)),
      DataCell(Text(readDate)),
      DataCell(ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
        onPressed: () {},
        child: const Text('Написать сообщение'),
      )),
    ]);
  }
}
