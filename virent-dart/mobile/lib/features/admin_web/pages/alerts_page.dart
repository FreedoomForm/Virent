import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Тревоги',
      provider: alertsListProvider,
      searchProvider: _alertSearchProvider,
      searchMatcher: (a, query) {
        final sid = (a['scooter_id'] ?? a['scooterId'] ?? '').toString().toLowerCase();
        final type = (a['type'] ?? a['alert_type'] ?? a['message'] ?? '').toString().toLowerCase();
        return sid.contains(query) || type.contains(query);
      },
      filters: Row(
        children: [
          SizedBox(
            width: 150,
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Самокат', style: TextStyle(color: Colors.grey, height: 2.2)),
                ),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onChanged: (v) =>
                  ref.read(_alertSearchProvider.notifier).state = v,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              value: 'Типы тревог:',
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              ),
              items: const [
                DropdownMenuItem(value: 'Типы тревог:', child: Text('Типы тревог:')),
              ],
              onChanged: (val) {},
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => showAdminSnack(context, 'Фильтр «Открыта» применён'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDA4453), foregroundColor: adminPrimaryForeground),
            child: const Text('Открыта'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => showAdminSnack(context, 'Фильтр «Закрыта» применён'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF37BC9B), foregroundColor: adminPrimaryForeground),
            child: const Text('Закрыта'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => showAdminSnack(context, 'Группировка включена'),
            style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
            child: const Text('Группировать'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(_alertSearchProvider.notifier).state = '';
              showAdminSnack(context, 'Фильтр сброшен');
            },
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Сбросить фильтр'),
          ),
        ],
      ),
      columns: const [
        DataColumn(label: Text('Icon')),
        DataColumn(label: Text('scooterId')),
        DataColumn(label: Text('alertType')),
        DataColumn(label: Text('time')),
        DataColumn(label: Text('status')),
      ],
      buildRow: (a) {
        final sid = (a['scooter_id'] ?? a['scooterId'] ?? '-').toString();
        final type = (a['type'] ?? a['alert_type'] ?? a['message'] ?? '-').toString();
        final time = (a['time'] ?? a['created_at'] ?? a['timestamp'] ?? '-').toString();
        final status = (a['status'] ?? a['state'] ?? 'open').toString().toLowerCase();
        final isClosed = status == 'closed' || status == 'resolved';
        final bgColor = isClosed ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2);
        IconData icon;
        Color iconColor;
        if (isClosed) {
          icon = Icons.check_box;
          iconColor = Colors.green;
        } else if (type.toLowerCase().contains('без связи') ||
            type.toLowerCase().contains('offline')) {
          icon = Icons.signal_cellular_off;
          iconColor = Colors.red;
        } else {
          icon = Icons.lock;
          iconColor = Colors.orange;
        }
        final statusLabel = isClosed ? 'Тревога закрыта' : 'Тревога';
        return DataRow(
          color: WidgetStateProperty.all(bgColor),
          cells: [
            DataCell(Container(
              padding: const EdgeInsets.all(4),
              color: Colors.black,
              child: Icon(icon, color: iconColor, size: 16),
            )),
            DataCell(Text(sid, style: adminLinkStyle)),
            DataCell(Text(type)),
            DataCell(Text(time)),
            DataCell(Text(statusLabel)),
          ],
        );
      },
    );
  }
}

final _alertSearchProvider = StateProvider<String>((ref) => '');
