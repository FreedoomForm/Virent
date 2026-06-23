import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class SettingsNotificationsPage extends ConsumerWidget {
  const SettingsNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsNotificationsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Настройки уведомлений', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('', style: TextStyle(color: Colors.grey)),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
              elevation: 0,
              child: asyncSettings.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
                data: (settings) {
                  final events = (settings['events'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
                  if (events.isEmpty) {
                    return const Center(child: Text('В таблице нет доступных данных', style: TextStyle(color: Colors.grey)));
                  }
                  return SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('Event')),
                        DataColumn(label: Text('Send sms')),
                        DataColumn(label: Text('Send push')),
                        DataColumn(label: Text('Send email')),
                        DataColumn(label: Text('Email content')),
                        DataColumn(label: Text('Sms content')),
                        DataColumn(label: Text('Действия')),
                      ],
                      rows: events.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final event = entry.value;
                        return DataRow(cells: [
                          DataCell(Text((idx + 1).toString())),
                          DataCell(Text((event['event'] ?? event['name'] ?? '-').toString())),
                          DataCell(Text((event['send_sms'] ?? event['sms'] ?? '').toString())),
                          DataCell(Text((event['send_push'] ?? event['push'] ?? '').toString())),
                          DataCell(Text((event['send_email'] ?? event['email'] ?? '').toString())),
                          DataCell(Text((event['email_content'] ?? '').toString())),
                          DataCell(Text((event['sms_content'] ?? '').toString())),
                          DataCell(Row(
                            children: [
                              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
