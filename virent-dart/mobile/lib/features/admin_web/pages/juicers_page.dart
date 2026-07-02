import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class JuicersPage extends ConsumerWidget {
  const JuicersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Джусеры',
      provider: juicersListProvider,
      searchProvider: _juicerSearchProvider,
      searchMatcher: (j, query) {
        final id = (j['id'] ?? '').toString().toLowerCase();
        final name = (j['name'] ?? j['full_name'] ?? '').toString().toLowerCase();
        final phone = (j['phone'] ?? j['mobile'] ?? '').toString().toLowerCase();
        return id.contains(query) || name.contains(query) || phone.contains(query);
      },
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить джусера',
          fields: const [
            AdminField(key: 'name', label: 'Имя'),
            AdminField(key: 'phone', label: 'Телефон', hint: '+998901234567'),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/juicers',
              values,
              juicersListProvider);
          }),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить джусера'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground)),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Имя')),
        DataColumn(label: Text('Телефон')),
        DataColumn(label: Text('Заряжено')),
        DataColumn(label: Text('Заработано')),
        DataColumn(label: Text('Статус')),
      ],
      buildRow: (j) {
        final id = (j['id'] ?? '-').toString();
        final name = (j['name'] ?? j['full_name'] ?? '-').toString();
        final phone = (j['phone'] ?? j['mobile'] ?? '-').toString();
        final charged = (j['charged'] ?? j['charged_count'] ?? j['scooters_charged'] ?? '-').toString();
        final earned = (j['earned'] ?? j['earnings'] ?? j['balance'] ?? '-').toString();
        final status = (j['status'] ?? j['state'] ?? '-').toString();
        final isActive = status.toLowerCase() == 'active' || status.toLowerCase() == 'online';
        final statusColor = isActive ? Colors.green : Colors.red;
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name, style: adminLinkStyle)),
          DataCell(Text(phone)),
          DataCell(Text(charged)),
          DataCell(Text(earned)),
          DataCell(Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold))),
        ]);
      });
  }
}

final _juicerSearchProvider = StateProvider<String>((ref) => '');
