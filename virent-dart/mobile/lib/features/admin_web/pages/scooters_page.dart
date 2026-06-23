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
          ],
          onSubmit: (values) async {
            await ref.read(createScooterAction)(values);
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Gosnomer')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Locks')),
        DataColumn(label: Text('Battery')),
        DataColumn(label: Text('Speed')),
        DataColumn(label: Text('Geozones')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (s) {
        String _s(String key) => (s[key] ?? '-').toString();
        final id = _s('id');
        final gosnomer = _s('gosnomer') == '-' ? _s('qr_code') : _s('gosnomer');
        final status = _s('status') == '-' ? _s('state') : _s('status');
        final locks = _s('locks');
        final battery = _s('battery') == '-' ? _s('battery_level') : _s('battery');
        final speed = _s('speed');
        final geozones = _s('geozones') == '-' ? _s('zone') : _s('geozones');
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(gosnomer, style: adminLinkStyle)),
          DataCell(_statusChip(status)),
          DataCell(Text(locks == '-' ? '0' : locks)),
          DataCell(Text('$battery%')),
          DataCell(Text(speed == '-' ? '0' : speed)),
          DataCell(Text(geozones)),
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

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'online':
      case 'free':
        color = Colors.green;
        break;
      case 'rented':
      case 'in_use':
        color = Colors.purple;
        break;
      case 'offline':
        color = Colors.grey;
        break;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

final _scooterSearchProvider = StateProvider<String>((ref) => '');
