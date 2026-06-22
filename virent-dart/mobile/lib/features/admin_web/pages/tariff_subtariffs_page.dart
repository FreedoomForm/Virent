import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class TariffSubTariffsPage extends ConsumerWidget {
  const TariffSubTariffsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Subscription_tariffs',
      provider: tariffSubscriptionsProvider,
      searchProvider: _subtariffsSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить subscription_tariff',
          fields: const [
            AdminField(key: 'name', label: 'Name'),
            AdminField(key: 'name_in_app', label: 'Name in app'),
            AdminField(key: 'price', label: 'Price', initial: '0'),
            AdminField(key: 'group', label: 'Group'),
            AdminField(key: 'active', label: 'Active', initial: '0'),
            AdminField(key: 'daily', label: 'Daily', initial: '0'),
            AdminField(key: 'company', label: 'Company'),
            AdminField(key: 'duration', label: 'Duration', initial: '0'),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/tariff-subscriptions',
              values,
              tariffSubscriptionsProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить subscription_tariff'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      filters: SizedBox(
        width: 150,
        child: TextField(
          decoration: adminFilterDecoration(hint: 'ID подписки'),
        ),
      ),
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Name in app')),
        DataColumn(label: Text('Price')),
        DataColumn(label: Text('Group')),
        DataColumn(label: Text('Active')),
        DataColumn(label: Text('Daily')),
        DataColumn(label: Text('Company')),
        DataColumn(label: Text('Duration')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(_s('name'))),
          DataCell(Text(_s('name_in_app'))),
          DataCell(Text(_s('price'))),
          DataCell(Text(_s('group'))),
          DataCell(Text(_s('active'))),
          DataCell(Text(_s('daily'))),
          DataCell(Text(_s('company'))),
          DataCell(Text(_s('duration'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminViewDialog(context, title: 'Subscription_tariff #$id', item: item),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Просмотр'),
              ),
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать subscription_tariff #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'name', label: 'Name', initial: _s('name')),
                    AdminField(key: 'name_in_app', label: 'Name in app', initial: _s('name_in_app')),
                    AdminField(key: 'price', label: 'Price', initial: _s('price')),
                    AdminField(key: 'group', label: 'Group', initial: _s('group')),
                    AdminField(key: 'active', label: 'Active', initial: _s('active')),
                    AdminField(key: 'daily', label: 'Daily', initial: _s('daily')),
                    AdminField(key: 'company', label: 'Company', initial: _s('company')),
                    AdminField(key: 'duration', label: 'Duration', initial: _s('duration')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/tariff-subscriptions', id, values, tariffSubscriptionsProvider);
                  },
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              TextButton.icon(
                onPressed: () => showAdminDeleteDialog(
                  context,
                  name: _s('name'),
                  onDelete: () async {
                    await ref.read(genericDeleteAction)('/admin/tariff-subscriptions', id, tariffSubscriptionsProvider);
                  },
                ),
                icon: const Icon(Icons.delete, size: 14),
                label: const Text('Удалить'),
              ),
            ],
          )),
        ]);
      },
    );
  }
}

final _subtariffsSearchProvider = StateProvider<String>((ref) => '');
