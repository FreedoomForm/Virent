import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class GeozonesPage extends ConsumerWidget {
  const GeozonesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Геозоны',
      provider: zonesListProvider,
      searchProvider: _zoneSearchProvider,
      searchMatcher: (z, query) {
        final name = (z['name'] ?? z['title'] ?? '').toString().toLowerCase();
        return name.contains(query);
      },
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить геозону',
          fields: const [
            AdminField(key: 'name', label: 'Название'),
            AdminField(key: 'fill_color', label: 'Заполнение (hex)'),
            AdminField(key: 'stroke_color', label: 'Обводка (hex)'),
            AdminField(key: 'groups', label: 'Группы'),
            AdminField(key: 'fill_opacity', label: 'кэф.проз.геозоны'),
            AdminField(key: 'stroke_opacity', label: 'кэф.ярк.обводки'),
            AdminField(key: 'commands', label: 'Команды'),
          ],
          onSubmit: (values) async {
            await ref.read(createZoneAction)(values);
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить геозону'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Название')),
        DataColumn(label: Text('Заполнение')),
        DataColumn(label: Text('Обводка')),
        DataColumn(label: Text('Группы')),
        DataColumn(label: Text('кэф.проз.геозоны')),
        DataColumn(label: Text('кэф.ярк.обводки')),
        DataColumn(label: Text('Команды')),
        DataColumn(label: Text('Зона Разрешенного...')),
        DataColumn(label: Text('Зона Завершения...')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (z) {
        String _s(String key) => (z[key] ?? '-').toString();
        bool _b(String key) {
          final v = z[key];
          if (v == null) return false;
          if (v is bool) return v;
          final s = v.toString().toLowerCase();
          return s == '1' || s == 'true' || s == 'yes';
        }
        final id = _s('id');
        final name = _s('name') == '-' ? _s('title') : _s('name');
        final fill = _s('fill_color') == '-' ? '#cc62dc' : _s('fill_color');
        final stroke = _s('stroke_color') == '-' ? '#1bffca' : _s('stroke_color');
        final groups = _s('groups');
        final alpha = _s('fill_opacity');
        final beta = _s('stroke_opacity');
        final cmds = _s('commands');
        final allowed = _b('allowed_zone');
        final finish = _b('finish_zone');
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name, style: adminLinkStyle)),
          DataCell(Text(fill)),
          DataCell(Text(stroke)),
          DataCell(Text(groups == '-' ? '-' : groups)),
          DataCell(Text(alpha == '-' ? '30 %' : alpha)),
          DataCell(Text(beta == '-' ? '30 %' : beta)),
          DataCell(Text(cmds)),
          DataCell(Icon(allowed ? Icons.check_box : Icons.check_box_outline_blank, color: allowed ? Colors.green : Colors.red)),
          DataCell(Icon(finish ? Icons.check_box : Icons.check_box_outline_blank, color: finish ? Colors.green : Colors.red)),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр')),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить')),
            ],
          )),
        ]);
      },
    );
  }
}

final _zoneSearchProvider = StateProvider<String>((ref) => '');
