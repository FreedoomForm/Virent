import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class ScootersPage extends ConsumerWidget {
  const ScootersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Самокаты',
      provider: scootersListProvider,
      searchProvider: _scooterSearchProvider,
      searchMatcher: (s, query) {
        final id = (s['id'] ?? '').toString().toLowerCase();
        final qr = (s['qr_code'] ?? s['gosnomer'] ?? s['mac'] ?? '').toString().toLowerCase();
        final comment = (s['comment'] ?? '').toString().toLowerCase();
        return id.contains(query) || qr.contains(query) || comment.contains(query);
      },
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить самокат',
          fields: const [
            AdminField(key: 'qr_code', label: 'QR / Госномер'),
            AdminField(key: 'mac', label: 'MAC-адрес'),
            AdminField(key: 'model', label: 'Модель'),
            AdminField(key: 'comment', label: 'Комментарий', multiline: true),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/scooters',
              values,
              scootersListProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить самокат'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      filters: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterField('Номер'),
            const SizedBox(width: 8),
            _buildFilterField('Комментарий', width: 200),
            const SizedBox(width: 8),
            _buildFilterField('От (%)', width: 80),
            const SizedBox(width: 8),
            _buildFilterField('До (%)', width: 80),
            const SizedBox(width: 8),
            _buildDropdownBtn(context, 'Модель'),
            const SizedBox(width: 8),
            _buildDropdownBtn(context, 'Группы'),
            const SizedBox(width: 8),
            _buildDropdownBtn(context, 'Компания'),
            const SizedBox(width: 8),
            _buildDropdownBtn(context, 'Геозоны'),
          ],
        ),
      ),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('QR/Gosnomer')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Battery')),
        DataColumn(label: Text('Speed')),
        DataColumn(label: Text('Geozones')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (s) {
        final id = (s['id'] ?? '-').toString();
        final qr = (s['qr_code'] ?? s['gosnomer'] ?? s['mac'] ?? '-').toString();
        final status = (s['status'] ?? s['state'] ?? 'offline').toString().toLowerCase();
        final battery = (s['battery'] ?? s['battery_level'] ?? '-').toString();
        final speed = (s['speed'] ?? '-').toString();
        final geo = (s['geozones'] ?? s['zone'] ?? '-').toString();
        final mac = (s['mac'] ?? s['flespi_id'] ?? '').toString();
        final isOnline = status == 'online' || status == 'ready' || status == 'active';
        final statusColor = isOnline ? Colors.green : Colors.red;
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(qr, style: adminLinkStyle)),
          DataCell(Text(status.toUpperCase(),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold))),
          DataCell(Text('$battery %')),
          DataCell(Text('$speed км/ч')),
          DataCell(Text(geo, style: adminLinkStyle)),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminViewDialog(
                  context,
                  title: 'Самокат #$id',
                  item: s,
                ),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Просмотр'),
              ),
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать самокат #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'qr_code', label: 'QR / Госномер', initial: qr),
                    AdminField(key: 'mac', label: 'MAC-адрес', initial: mac),
                    AdminField(key: 'model', label: 'Модель', initial: (s['model'] ?? '').toString()),
                    AdminField(key: 'comment', label: 'Комментарий', multiline: true, initial: (s['comment'] ?? '').toString()),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)(
                      '/admin/scooters',
                      id,
                      values,
                      scootersListProvider,
                    );
                  },
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              IconButton(
                tooltip: 'Блокировка',
                onPressed: mac.isEmpty
                    ? null
                    : () => runAdminAction(
                          context,
                          () => ref.read(sendIoTCommandAction)(mac, 'lock'),
                          successMessage: 'Команда lock отправлена',
                        ),
                icon: const Icon(Icons.lock, size: 16, color: Colors.red),
              ),
              IconButton(
                tooltip: 'Разблокировка',
                onPressed: mac.isEmpty
                    ? null
                    : () => runAdminAction(
                          context,
                          () => ref.read(sendIoTCommandAction)(mac, 'unlock'),
                          successMessage: 'Команда unlock отправлена',
                        ),
                icon: const Icon(Icons.lock_open, size: 16, color: Colors.green),
              ),
            ],
          )),
        ]);
      },
    );
  }

  Widget _buildFilterField(String hint, {double width = 120}) {
    return SizedBox(
      width: width,
      child: TextField(
        decoration: adminFilterDecoration(hint: hint),
      ),
    );
  }

  Widget _buildDropdownBtn(BuildContext context, String label) {
    return ElevatedButton.icon(
      onPressed: () => showAdminInfoDialog(
          context, label, 'Фильтр "$label" — выберите значение.'),
      icon: const Icon(Icons.arrow_drop_down, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: adminPrimaryColor,
        foregroundColor: adminPrimaryForeground,
      ),
    );
  }
}

final _scooterSearchProvider = StateProvider<String>((ref) => '');
