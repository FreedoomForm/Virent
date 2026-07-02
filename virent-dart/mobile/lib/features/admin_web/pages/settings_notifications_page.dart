import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_export.dart';
import '../widgets/admin_status_tabs.dart';
import '../widgets/admin_colors.dart';

class SettingsNotificationsPage extends ConsumerStatefulWidget {
  const SettingsNotificationsPage({super.key});
  @override
  ConsumerState<SettingsNotificationsPage> createState() => _SettingsNotificationsPageState();
}

class _SettingsNotificationsPageState extends ConsumerState<SettingsNotificationsPage> {
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

  /// Normalizes the Map response from settingsNotificationsProvider into a
  /// flat List of event rows. Supports both shapes:
  ///   - {"events": [{"event": "x", "send_sms": 1, ...}, ...]}
  ///   - {"trip_started": {"send_sms": 1, ...}, ...}
  List<Map<String, dynamic>> _normalize(Map<String, dynamic> data) {
    final rows = <Map<String, dynamic>>[];
    if (data['events'] is List) {
      for (final e in (data['events'] as List)) {
        if (e is Map) rows.add(Map<String, dynamic>.from(e));
      }
      return rows;
    }
    data.forEach((key, value) {
      if (value is Map) {
        final row = Map<String, dynamic>.from(value);
        row.putIfAbsent('event', () => key);
        rows.add(row);
      } else {
        rows.add({'event': key, 'value': value});
      }
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(settingsNotificationsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
      data: (config) {
        final items = _normalize(config);
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
                        const Text('Уведомления', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        const SizedBox(width: 12),
                        Text('Показано ${filtered.length} совпадений', style: const TextStyle(fontSize: 11, color: adminTextGray)),
                      ]),
                      ElevatedButton.icon(
                        onPressed: () => showAdminFormDialog(context, title: 'Добавить уведомление', fields: const [AdminField(key: 'event', label: 'Событие'), AdminField(key: 'send_sms', label: 'Отправить SMS'), AdminField(key: 'send_push', label: 'Отправить push')], onSubmit: (values) async { ref.invalidate(settingsNotificationsProvider); }),
                        icon: const Icon(Icons.add, size: 14, color: Colors.white),
                        label: const Text('Добавить уведомление', style: TextStyle(fontSize: 11, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: adminPrimary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3))))
                    ]),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.download, size: 18, color: adminTextSecondary), tooltip: 'Экспорт', onPressed: () => showAdminExportDialog(context, title: 'Экспорт', fields: ['event', 'send_sms', 'send_push', 'send_chat'], onExport: (fmt, fields) async {})),
                      IconButton(icon: const Icon(Icons.filter_list, size: 18, color: adminTextSecondary), tooltip: 'Фильтры', onPressed: () => showAdminFilterDialog(context, title: 'Фильтры', fields: const [AdminField(key: 'event', label: 'Событие')], onApply: (v) async {})),
                      SizedBox(width: 200, child: TextField(controller: _searchController, onChanged: (v) => setState(() { _query = v; _currentPage = 1; }), onSubmitted: (v) => setState(() { _query = v; _currentPage = 1; }), decoration: InputDecoration(hintText: 'Поиск...', prefixIcon: Icon(Icons.search, size: 18, color: adminTextGray), filled: true, fillColor: adminBgLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: adminBorder)), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true))),
                    ]),
                  ])),
              const SizedBox(height: 8),
              AdminStatusTabsRow(badges: [AdminStatusBadge(label: 'Всего', count: filtered.length, color: adminPrimary)]),
              const SizedBox(height: 8),
              if (_selectedIds.isNotEmpty) _buildBulkActionBar(context),
              Expanded(child: Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: adminBorder)), child: pageItems.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inbox, size: 40, color: adminBorder), SizedBox(height: 8), Text('Нет данных', style: TextStyle(color: adminTextGray, fontSize: 13))]))) : SingleChildScrollView(child: DataTable(headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: adminTextDark),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) return adminBgLight;
              return Colors.white;
            }),
            dataRowMinHeight: 40,
            dataRowMaxHeight: 40,
            columnSpacing: 24,
            horizontalMargin: 12,
                    headingRowColor: WidgetStateProperty.all(adminBgLight), columns: [const DataColumn(label: Text('')), const DataColumn(label: Text('#')), const DataColumn(label: Text('Event')), const DataColumn(label: Text('Send sms')), const DataColumn(label: Text('Send push')), const DataColumn(label: Text('Send chat')), const DataColumn(label: Text('Действия'))], rows: pageItems.asMap().entries.map<DataRow>((entry) { final copy = Map<String, dynamic>.from(entry.value); copy['#'] = entry.key + 1; return _buildRow(context, ref, copy); }).toList())))),
              _buildPaginationBar(filtered.length, totalPages),
            ]));
      });
  }

  bool _truthy(dynamic v) => v == true || v == 1 || v == '1' || v == 'true' || v == 'yes';

  DataRow _buildRow(BuildContext context, WidgetRef ref, Map<String, dynamic> item) {
    final key = item['event'] ?? item['id'] ?? item['#'];
    return DataRow(cells: [
      DataCell(Checkbox(value: _selectedIds.contains(key), onChanged: (_) => setState(() { if (_selectedIds.contains(key)) { _selectedIds.remove(key); } else { _selectedIds.add(key); } }))),
      DataCell(Text("${item['#'] ?? ''}")),
      DataCell(Text("${item['event'] ?? item['name'] ?? ''}")),
      DataCell(Icon(_truthy(item['send_sms']) ? Icons.check_box : Icons.check_box_outline_blank, size: 14, color: _truthy(item['send_sms']) ? adminSuccess : adminTextGray)),
      DataCell(Icon(_truthy(item['send_push']) ? Icons.check_box : Icons.check_box_outline_blank, size: 14, color: _truthy(item['send_push']) ? adminSuccess : adminTextGray)),
      DataCell(Icon(_truthy(item['send_chat']) ? Icons.check_box : Icons.check_box_outline_blank, size: 14, color: _truthy(item['send_chat']) ? adminSuccess : adminTextGray)),
      DataCell(Row(children: [
        TextButton.icon(onPressed: () => showAdminViewDialog(context, title: 'Просмотр', item: item), icon: const Icon(Icons.visibility, size: 12, color: adminInfo), label: const Text('Просмотр', style: TextStyle(fontSize: 10, color: adminInfo))),
        TextButton.icon(onPressed: () => showAdminFormDialog(context, title: 'Редактировать', fields: [AdminField(key: 'event', label: 'Событие', initial: "${item['event'] ?? item['name'] ?? ''}"), AdminField(key: 'send_sms', label: 'Send sms (0/1)', initial: _truthy(item['send_sms']) ? '1' : '0'), AdminField(key: 'send_push', label: 'Send push (0/1)', initial: _truthy(item['send_push']) ? '1' : '0'), AdminField(key: 'send_chat', label: 'Send chat (0/1)', initial: _truthy(item['send_chat']) ? '1' : '0')], onSubmit: (v) async { ref.invalidate(settingsNotificationsProvider); }, isEdit: true), icon: const Icon(Icons.edit, size: 12, color: adminInfo), label: const Text('Редактировать', style: TextStyle(fontSize: 10, color: adminInfo))),
        TextButton.icon(onPressed: () => showAdminDeleteDialog(context, name: 'Уведомление', onDelete: () async { ref.invalidate(settingsNotificationsProvider); }), icon: const Icon(Icons.delete, size: 12, color: adminDanger), label: const Text('Удалить', style: TextStyle(fontSize: 10, color: adminDanger))),
      ])),
    ]);
  }

  Widget _buildBulkActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: adminBgLight,
      child: Row(children: [
        Text('Выбрано: ${_selectedIds.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(width: 16),
        TextButton.icon(onPressed: () => showAdminBulkActionDialog(context, title: 'Удалить', message: 'Удалить выбранные уведомления?', selectedCount: _selectedIds.length, onConfirm: () async { _selectedIds.clear(); }), icon: const Icon(Icons.delete, size: 14, color: adminDanger), label: const Text('Удалить', style: TextStyle(color: adminDanger, fontSize: 11))),
        const Spacer(),
        TextButton(onPressed: () => setState(() => _selectedIds.clear()), child: const Text('Отменить', style: TextStyle(fontSize: 11))),
      ]));
  }

  Widget _buildPaginationBar(int total, int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(alignment: WrapAlignment.spaceBetween, children: [
        Text('Показано ${min(_currentPage * _pageSize, total)} из $total', style: const TextStyle(fontSize: 11, color: adminTextGray)),
        Row(children: [
          IconButton(tooltip: 'Предыдущая страница', icon: const Icon(Icons.chevron_left, size: 16), onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
          Text('$_currentPage / $totalPages', style: const TextStyle(fontSize: 11)),
          IconButton(tooltip: 'Следующая страница', icon: const Icon(Icons.chevron_right, size: 16), onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
        ]),
      ]));
  }
}
