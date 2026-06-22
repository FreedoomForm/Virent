import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class TechFeedbackPage extends ConsumerWidget {
  const TechFeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Фидбек',
      provider: techFeedbackProvider,
      searchProvider: _feedbackSearchProvider,
      filters: Row(
        children: [
          _buildFilterInput('Самокат'),
          const SizedBox(width: 8),
          _buildFilterInput('Заказ'),
          const SizedBox(width: 8),
          _buildFilterInput('Клиент'),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => showAdminSnack(context, 'Фильтр «Проверен» применён'),
            style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
            child: const Text('Проверен'),
          ),
        ],
      ),
      columns: const [
        DataColumn(label: Text('id')),
        DataColumn(label: Text('car_id')),
        DataColumn(label: Text('client_id')),
        DataColumn(label: Text('order_id')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('checked')),
        DataColumn(label: Text('Who checked')),
        DataColumn(label: Text('created_at')),
        DataColumn(label: Text('updated_at')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(_s('car_id'), style: adminLinkStyle)),
          DataCell(Text(_s('client_id'), style: adminLinkStyle)),
          DataCell(Text(_s('order_id'), style: adminLinkStyle)),
          DataCell(Text(_s('type'))),
          const DataCell(Icon(Icons.check_box_outline_blank, color: Colors.grey)),
          DataCell(Text(_s('who_checked'))),
          DataCell(Text(_s('created_at'))),
          DataCell(Text(_s('updated_at'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminViewDialog(
                  context,
                  title: 'Фидбэк #$id',
                  item: item,
                ),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Просмотр'),
              ),
              TextButton.icon(
                onPressed: () => runAdminAction(
                  context,
                  () => ref.read(genericUpdateAction)('/admin/tech-feedback', id, {'checked': '1'}, techFeedbackProvider),
                  successMessage: 'Фидбэк отмечен проверенным',
                ),
                icon: const Icon(Icons.check, size: 14),
                label: const Text('Проверить фидбэк'),
              ),
            ],
          )),
        ]);
      },
    );
  }

  Widget _buildFilterInput(String label) {
    return SizedBox(
      width: 150,
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label, style: const TextStyle(color: Colors.grey, height: 2.2)),
          ),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}

final _feedbackSearchProvider = StateProvider<String>((ref) => '');
