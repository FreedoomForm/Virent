import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_providers.dart' show apiClientProvider;
import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';

class SettingsNotificationsPage extends ConsumerWidget {
  const SettingsNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(settingsNotificationsProvider);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Entries', style: TextStyle(fontSize: 24)),
              Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      async.maybeWhen(data: (data) => 'Показано 1 до ${(data['items'] as List?)?.length ?? 0} из ${(data['items'] as List?)?.length ?? 0} совпадений', orElse: () => 'Загрузка...'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )),
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Поиск...',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
              elevation: 0,
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e', style: const TextStyle(color: Colors.red))),
                data: (config) {
                  final rawItems = config['items'] as List? ?? [];
                  final items = rawItems.cast<Map<String, dynamic>>();
                  if (items.isEmpty) {
                    return ListView(
                      children: [
                        DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
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
                          rows: const [],
                        ),
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: Text('В таблице нет доступных данных', style: TextStyle(color: Colors.grey))),
                        )
                      ],
                    );
                  }
                  return ListView(
                    children: [
                      DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
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
                        rows: items.asMap().entries.map((e) => _buildRow(context, ref, e)).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  DataRow _buildRow(BuildContext context, WidgetRef ref, MapEntry<int, Map<String, dynamic>> entry) {
    final item = entry.value;
    String _s(String key) => (item[key] ?? '-').toString();
    bool _b(String key) {
      final v = item[key];
      if (v == null) return false;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      return s == '1' || s == 'true' || s == 'yes';
    }
    final id = _s('id');
    return DataRow(cells: [
      DataCell(Text('${entry.key + 1}')),
      DataCell(Text(_s('event'))),
      DataCell(Switch(value: _b('send_sms'), onChanged: (val) {})),
      DataCell(Switch(value: _b('send_push'), onChanged: (val) {})),
      DataCell(Switch(value: _b('send_email'), onChanged: (val) {})),
      DataCell(Text(_s('email_content'))),
      DataCell(Text(_s('sms_content'))),
      DataCell(Row(
        children: [
          TextButton.icon(
            onPressed: () => showAdminFormDialog(
              context,
              title: 'Редактировать уведомление #${id}',
              isEdit: true,
              fields: [
                AdminField(key: 'event', label: 'Событие', initial: _s('event')),
                AdminField(key: 'send_sms', label: 'Отправлять SMS (0/1)', initial: _b('send_sms') ? '1' : '0'),
                AdminField(key: 'send_push', label: 'Отправлять PUSH (0/1)', initial: _b('send_push') ? '1' : '0'),
                AdminField(key: 'send_email', label: 'Отправлять email (0/1)', initial: _b('send_email') ? '1' : '0'),
                AdminField(key: 'sms_content', label: 'Текст SMS', multiline: true, initial: _s('sms_content')),
                AdminField(key: 'email_content', label: 'Текст email', multiline: true, initial: _s('email_content')),
              ],
              onSubmit: (values) async {
                await ref.read(apiClientProvider).put('/admin/settings/notifications/$id', values);
                ref.invalidate(settingsNotificationsProvider);
              },
            ),
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Редактировать'),
          ),
          TextButton.icon(
            onPressed: () => showAdminDeleteDialog(
              context,
              name: _s('event'),
              onDelete: () async {
                await ref.read(apiClientProvider).delete('/admin/settings/notifications/$id');
                ref.invalidate(settingsNotificationsProvider);
              },
            ),
            icon: const Icon(Icons.delete, size: 14),
            label: const Text('Удалить'),
          ),
        ],
      )),
    ]);
  }
}
