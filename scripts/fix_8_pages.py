#!/usr/bin/env python3
"""Fix 8 pages missing all features - using string replacement."""
import os

PAGES_DIR = "/home/z/my-project/virent-dart/mobile/lib/features/admin_web/pages"

PAGES = [
    {
        'file': 'tariffs_page.dart',
        'class': 'TariffsPage',
        'title': 'Тарифы',
        'provider': 'tariffsListProvider',
        'add_label': 'Добавить тариф',
        'columns': [('ID', 'id'), ('Название в админке', 'name_admin'), ('Название в приложении', 'name_app'), ('Hold', 'hold'), ('Действия', None)],
        'fields': [('name_admin', 'Название в админке'), ('name_app', 'Название в приложении'), ('hold', 'Hold')],
    },
    {
        'file': 'tariff_subtariffs_page.dart',
        'class': 'TariffSubtariffsPage',
        'title': 'Подписочные тарифы',
        'provider': 'tariffSubscriptionsProvider',
        'add_label': 'Добавить подписочный тариф',
        'columns': [('Name', 'name'), ('Name in app', 'name_app'), ('Price', 'price'), ('Group', 'group'), ('Active', 'active'), ('Действия', None)],
        'fields': [('name', 'Name'), ('name_app', 'Name in app'), ('price', 'Price'), ('group', 'Group')],
    },
    {
        'file': 'tariffs_subscriptions_page.dart',
        'class': 'TariffsSubscriptionsPage',
        'title': 'Подписочные тарифы',
        'provider': 'tariffSubscriptionsProvider',
        'add_label': 'Добавить подписочный тариф',
        'columns': [('Name', 'name'), ('Name in app', 'name_app'), ('Price', 'price'), ('Group', 'group'), ('Active', 'active'), ('Действия', None)],
        'fields': [('name', 'Name'), ('name_app', 'Name in app'), ('price', 'Price'), ('group', 'Group')],
    },
    {
        'file': 'task_technicians_page.dart',
        'class': 'TaskTechniciansPage',
        'title': 'Задачи техников',
        'provider': 'techTasksProvider',
        'add_label': 'Добавить задачу',
        'columns': [('id', 'id'), ('Title', 'title'), ('Technician', 'technician'), ('Description', 'description'), ('Create by', 'create_by'), ('Create time', 'create_time'), ('Завершен', 'done'), ('Finish time', 'finish_time'), ('Действия', None)],
        'fields': [('title', 'Title'), ('technician', 'Technician'), ('description', 'Description')],
    },
    {
        'file': 'settings_drivers_page.dart',
        'class': 'SettingsDriversPage',
        'title': 'Драйверы',
        'provider': 'settingsDriversProvider',
        'add_label': 'Добавить запись',
        'columns': [('id', 'id'), ('Value', 'value'), ('Description', 'description'), ('Type', 'type'), ('Действия', None)],
        'fields': [('value', 'Value'), ('description', 'Description'), ('type', 'Type')],
    },
    {
        'file': 'settings_scooter_groups_page.dart',
        'class': 'SettingsScooterGroupsPage',
        'title': 'Группы самокатов',
        'provider': 'settingsScooterGroupsProvider',
        'add_label': 'Добавить запись',
        'columns': [('id', 'id'), ('Description', 'description'), ('Trigger equation', 'trigger_equation'), ('Действия', None)],
        'fields': [('description', 'Description'), ('trigger_equation', 'Trigger equation')],
    },
    {
        'file': 'sms_logs_page.dart',
        'class': 'SmsLogsPage',
        'title': 'Логи SMS',
        'provider': 'smsLogsProvider',
        'add_label': '',
        'columns': [('Id', 'id'), ('Phone', 'phone'), ('Sms code', 'sms_code'), ('Sms try count', 'try_count'), ('Sms try count all', 'try_count_all'), ('Sms try login', 'try_login'), ('Create time', 'create_time'), ('Sms last attempt', 'last_attempt'), ('Check key', 'check_key'), ('Действия', None)],
        'fields': [('phone', 'Phone'), ('sms_code', 'Sms code')],
    },
    {
        'file': 'iot_page.dart',
        'class': 'IotPage',
        'title': 'IoT устройства',
        'provider': 'iotLogsProvider',
        'add_label': '',
        'columns': [('Id', 'id'), ('Mac', 'mac'), ('Model', 'model'), ('Status', 'status'), ('Действия', None)],
        'fields': [('mac', 'Mac'), ('model', 'Model'), ('status', 'Status')],
    },
]


def make_fields_list(fields, with_initial=False):
    parts = []
    for k, l in fields:
        if with_initial:
            parts.append("AdminField(key: '%s', label: '%s', initial: '${item[\\'%s\\'] ?? \\'\\'}')" % (k, l, k))
        else:
            parts.append("AdminField(key: '%s', label: '%s')" % (k, l))
    return '[' + ', '.join(parts) + ']'


def make_columns(columns):
    parts = ["const DataColumn(label: Text(''))"]  # checkbox col
    for label, key in columns:
        parts.append("const DataColumn(label: Text('%s'))" % label)
    return '[' + ', '.join(parts) + ']'


def make_data_cells(columns):
    parts = []
    for label, key in columns:
        if key is None:
            continue
        parts.append("      DataCell(Text('${item['%s'] ?? ''}'))" % key)
    return '\n'.join(parts)


def make_add_button(config):
    if not config['add_label']:
        return 'const SizedBox.shrink()'
    return """ElevatedButton.icon(
                      onPressed: () => showAdminFormDialog(context, title: '%s', fields: const %s, onSubmit: (v) async { ref.invalidate(%s); }),
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('%s', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C69EF), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3))),
                    )""" % (config['add_label'], make_fields_list(config['fields']), config['provider'], config['add_label'])


def generate_page(config):
    add_btn = make_add_button(config)
    cols = make_columns(config['columns'])
    cells = make_data_cells(config['columns'])
    edit_fields = make_fields_list(config['fields'], with_initial=True)
    export_fields = make_fields_list(config['fields'])
    
    content = """import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_export.dart';
import '../widgets/admin_status_tabs.dart';

class __CLASS__ extends ConsumerStatefulWidget {
  const __CLASS__({super.key});
  @override
  ConsumerState<__CLASS__> createState() => ___CLASS__State();
}

class ___CLASS__State extends ConsumerState<__CLASS__> {
  final _searchController = TextEditingController();
  final _selectedIds = <dynamic>{};
  String _query = '';
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(__PROVIDER__);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
      data: (items) {
        var filtered = items;
        if (_query.isNotEmpty) {
          filtered = filtered.where((i) => i.values.any((v) => v != null && v.toString().toLowerCase().contains(_query.toLowerCase()))).toList();
        }
        final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 9999);
        final pageItems = filtered.skip((_currentPage - 1) * _pageSize).take(_pageSize).toList();
        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Text('__TITLE__', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF1B2A4E))),
                        const SizedBox(width: 12),
                        Text('Показано ${filtered.length} совпадений', style: const TextStyle(fontSize: 11, color: Color(0xFF868686))),
                      ]),
                      __ADD_BTN__
                    ]),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.download, size: 18, color: Color(0xFF6D737A)), tooltip: 'Экспорт', onPressed: () => showAdminExportDialog(context, title: 'Экспорт', fields: __EXPORT_FIELDS__, onExport: (fmt, fields) async {})),
                      IconButton(icon: const Icon(Icons.filter_list, size: 18, color: Color(0xFF6D737A)), tooltip: 'Фильтры', onPressed: () => showAdminFilterDialog(context, title: 'Фильтры', fields: const __FILTER_FIELDS__, onApply: (v) async {})),
                      SizedBox(width: 200, child: TextField(controller: _searchController, onChanged: (v) => setState(() { _query = v; _currentPage = 1; }), decoration: const InputDecoration(hintText: 'Поиск...', prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF868686)), filled: true, fillColor: Color(0xFFF1F4F8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Color(0xFFD9E2EF))), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true))),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AdminStatusTabsRow(badges: [AdminStatusBadge(label: 'Всего', count: filtered.length, color: const Color(0xFF7C69EF))]),
              const SizedBox(height: 8),
              if (_selectedIds.isNotEmpty) _buildBulkActionBar(),
              Expanded(child: Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFD9E2EF))), child: SingleChildScrollView(child: DataTable(headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F4F8)), columns: __COLS__, rows: pageItems.map((i) => _buildRow(context, ref, i)).toList())))),
              _buildPaginationBar(filtered.length, totalPages),
            ],
          ),
        );
      },
    );
  }

  DataRow _buildRow(BuildContext context, WidgetRef ref, Map<String, dynamic> item) {
    return DataRow(cells: [
      DataCell(Checkbox(value: _selectedIds.contains(item['id']), onChanged: (_) => setState(() { if (_selectedIds.contains(item['id'])) { _selectedIds.remove(item['id']); } else { _selectedIds.add(item['id']); } }))),
__CELLS__
      DataCell(Row(children: [
        TextButton.icon(onPressed: () => showAdminViewDialog(context, title: 'Просмотр', item: item), icon: const Icon(Icons.visibility, size: 12, color: Color(0xFF467FD0)), label: const Text('Просмотр', style: TextStyle(fontSize: 10, color: Color(0xFF467FD0)))),
        TextButton.icon(onPressed: () => showAdminFormDialog(context, title: 'Редактировать', fields: __EDIT_FIELDS__, onSubmit: (v) async { ref.invalidate(__PROVIDER__); }, isEdit: true), icon: const Icon(Icons.edit, size: 12, color: Color(0xFF467FD0)), label: const Text('Редактировать', style: TextStyle(fontSize: 10, color: Color(0xFF467FD0)))),
        TextButton.icon(onPressed: () => showAdminDeleteDialog(context, name: '__TITLE__', onDelete: () async { ref.invalidate(__PROVIDER__); }), icon: const Icon(Icons.delete, size: 12, color: Color(0xFFDF4759)), label: const Text('Удалить', style: TextStyle(fontSize: 10, color: Color(0xFFDF4759)))),
      ])),
    ]);
  }

  Widget _buildBulkActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF1F4F8),
      child: Row(children: [
        Text('Выбрано: ${_selectedIds.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(width: 16),
        TextButton.icon(onPressed: () => showAdminBulkActionDialog(context, title: 'Удалить', message: 'Удалить выбранные?', selectedCount: _selectedIds.length, onConfirm: () async { _selectedIds.clear(); }), icon: const Icon(Icons.delete, size: 14, color: Color(0xFFDF4759)), label: const Text('Удалить', style: TextStyle(color: Color(0xFFDF4759), fontSize: 11))),
        const Spacer(),
        TextButton(onPressed: () => setState(() => _selectedIds.clear()), child: const Text('Отменить', style: TextStyle(fontSize: 11))),
      ]),
    );
  }

  Widget _buildPaginationBar(int total, int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(alignment: WrapAlignment.spaceBetween, children: [
        Text('Показано ${min(_currentPage * _pageSize, total)} из $total', style: const TextStyle(fontSize: 11, color: Color(0xFF868686))),
        Row(children: [
          IconButton(icon: const Icon(Icons.chevron_left, size: 16), onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
          Text('$_currentPage / $totalPages', style: const TextStyle(fontSize: 11)),
          IconButton(icon: const Icon(Icons.chevron_right, size: 16), onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
        ]),
      ]),
    );
  }
}
"""
    content = content.replace('__CLASS__', config['class'])
    content = content.replace('__TITLE__', config['title'])
    content = content.replace('__PROVIDER__', config['provider'])
    content = content.replace('__ADD_BTN__', add_btn)
    content = content.replace('__EXPORT_FIELDS__', export_fields)
    content = content.replace('__FILTER_FIELDS__', export_fields)
    content = content.replace('__COLS__', cols)
    content = content.replace('__CELLS__', cells)
    content = content.replace('__EDIT_FIELDS__', edit_fields)
    return content


for config in PAGES:
    content = generate_page(config)
    filepath = os.path.join(PAGES_DIR, config['file'])
    with open(filepath, 'w') as f:
        f.write(content)
    print("Fixed: %s" % config['file'])

print("\n=== Done! 8 pages fixed ===")
