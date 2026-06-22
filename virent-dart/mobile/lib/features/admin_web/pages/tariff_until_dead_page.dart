import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class TariffUntilDeadPage extends ConsumerWidget {
  const TariffUntilDeadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Тариф Пока Не Сядет',
      provider: tariffsListProvider,
      searchProvider: _untilDeadSearchProvider,
      columns: const [
        DataColumn(label: Text('Название в мобильном приложении')),
        DataColumn(label: Text('Название в админке')),
        DataColumn(label: Text('Максимальная длительность в часах')),
        DataColumn(label: Text('Страховка(Тийны)')),
        DataColumn(label: Text('стоимость за 1 км(Тийны)')),
        DataColumn(label: Text('Уровень заряда')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(_s('name_app'), style: adminLinkStyle)),
          DataCell(Text(_s('name_admin'))),
          DataCell(Text(_s('max_duration_hours'))),
          DataCell(Text(_s('insurance'))),
          DataCell(Text(_s('price_per_km'))),
          DataCell(Text(_s('charge_level'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminViewDialog(context, title: 'Тариф ПНС #$id', item: item),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Просмотр'),
              ),
              TextButton.icon(
                onPressed: () => showAdminInfoDialog(context, 'Геозоны завершения', 'Показаны геозоны завершения тарифа ПНС #$id'),
                icon: const Icon(Icons.map, size: 14),
                label: const Text('Геозоны завершения'),
              ),
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать тариф ПНС #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'name_app', label: 'Название в приложении', initial: _s('name_app')),
                    AdminField(key: 'name_admin', label: 'Название в админке', initial: _s('name_admin')),
                    AdminField(key: 'max_duration_hours', label: 'Макс. длительность (ч)', initial: _s('max_duration_hours')),
                    AdminField(key: 'insurance', label: 'Страховка (Тийны)', initial: _s('insurance')),
                    AdminField(key: 'price_per_km', label: 'Цена за 1 км (Тийны)', initial: _s('price_per_km')),
                    AdminField(key: 'charge_level', label: 'Уровень заряда', initial: _s('charge_level')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/tariffs', id, values, tariffsListProvider);
                  },
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              TextButton.icon(
                onPressed: () => showAdminDeleteDialog(
                  context,
                  name: _s('name_admin'),
                  onDelete: () async {
                    await ref.read(genericDeleteAction)('/admin/tariffs', id, tariffsListProvider);
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

final _untilDeadSearchProvider = StateProvider<String>((ref) => '');
