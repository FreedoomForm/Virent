import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_export.dart';
import '../widgets/admin_status_tabs.dart';
import '../widgets/admin_colors.dart';

class ChatLogsPage extends ConsumerStatefulWidget {
  const ChatLogsPage({super.key});
  @override
  ConsumerState<ChatLogsPage> createState() => _ChatLogsPageState();
}

class _ChatLogsPageState extends ConsumerState<ChatLogsPage> {
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
    final async = ref.watch(chatLogsProvider);
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
                        const Text('Журнал чата', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        const SizedBox(width: 12),
                        Text('Показано ${filtered.length} совпадений', style: const TextStyle(fontSize: 11, color: adminTextGray)),
                      ]),
                      ElevatedButton.icon(
                        onPressed: () => showAdminFormDialog(context, title: 'Добавить сообщение', fields: const [AdminField(key: 'client_id', label: 'ID клиента'), AdminField(key: 'text', label: 'Текст')], onSubmit: (values) async { await ref.read(genericCreateAction)('/admin/chat-logs', values, chatLogsProvider); }),
                        icon: const Icon(Icons.add, size: 14, color: Colors.white),
                        label: const Text('Добавить сообщение', style: TextStyle(fontSize: 11, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: adminPrimary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3))))
                    ]),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.download, size: 18, color: adminTextSecondary), tooltip: 'Экспорт', onPressed: () => showAdminExportDialog(context, title: 'Экспорт', fields: ['client_id', 'message', 'timestamp', 'read_by_admin'], onExport: (fmt, fields) async {})),
                      IconButton(icon: const Icon(Icons.filter_list, size: 18, color: adminTextSecondary), tooltip: 'Фильтры', onPressed: () => showAdminFilterDialog(context, title: 'Фильтры', fields: const [AdminField(key: 'client_id', label: 'ID клиента'), AdminField(key: 'message', label: 'Сообщение')], onApply: (v) async {})),
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
                    headingRowColor: WidgetStateProperty.all(adminBgLight), columns: [const DataColumn(label: Text('')), const DataColumn(label: Text('client_id')), const DataColumn(label: Text('message')), const DataColumn(label: Text('image')), const DataColumn(label: Text('Anoxer')), const DataColumn(label: Text('timestamp')), const DataColumn(label: Text('Location')), const DataColumn(label: Text('read_by_admin')), const DataColumn(label: Text('read_date')), const DataColumn(label: Text('Действия'))], rows: pageItems.map<DataRow>((i) => _buildRow(context, ref, i)).toList())))),
              _buildPaginationBar(filtered.length, totalPages),
            ]));
      });
  }

  DataRow _buildRow(BuildContext context, WidgetRef ref, Map<String, dynamic> item) {
    final readByAdmin = item['read_by_admin'] == true || item['read_by_admin'] == 1 || item['read_by_admin'] == '1';
    final image = "${item['image'] ?? ''}";
    return DataRow(cells: [
      DataCell(Checkbox(value: _selectedIds.contains(item['id'] ?? item['client_id']), onChanged: (_) => setState(() { final k = item['id'] ?? item['client_id']; if (_selectedIds.contains(k)) { _selectedIds.remove(k); } else { _selectedIds.add(k); } }))),
      DataCell(Text("${item['client_id'] ?? ''}")),
      DataCell(Text("${item['message'] ?? item['text'] ?? ''}", overflow: TextOverflow.ellipsis)),
      DataCell(image.isNotEmpty
          ? InkWell(onTap: () => showAdminViewDialog(context, title: 'Изображение', item: item), child: const Icon(Icons.image, size: 16, color: adminInfo))
          : const Text('—', style: TextStyle(color: adminTextGray, fontSize: 11))),
      DataCell(Text("${item['anoxer'] ?? ''}")),
      DataCell(Text("${item['timestamp'] ?? item['created_at'] ?? ''}")),
      DataCell(Text("${item['location'] ?? item['geo'] ?? ''}", overflow: TextOverflow.ellipsis)),
      DataCell(Icon(readByAdmin ? Icons.check_box : Icons.check_box_outline_blank, size: 14, color: readByAdmin ? adminSuccess : adminTextGray)),
      DataCell(Text("${item['read_date'] ?? item['read_at'] ?? ''}")),
      DataCell(Row(children: [
        TextButton.icon(onPressed: () => showAdminViewDialog(context, title: 'Просмотр', item: item), icon: const Icon(Icons.visibility, size: 12, color: adminInfo), label: const Text('Просмотр', style: TextStyle(fontSize: 10, color: adminInfo))),
        TextButton.icon(onPressed: () => showAdminFormDialog(context, title: 'Редактировать', fields: [AdminField(key: 'message', label: 'Сообщение', initial: "${item['message'] ?? item['text'] ?? ''}", multiline: true)], onSubmit: (v) async { ref.invalidate(chatLogsProvider); }, isEdit: true), icon: const Icon(Icons.edit, size: 12, color: adminInfo), label: const Text('Редактировать', style: TextStyle(fontSize: 10, color: adminInfo))),
        TextButton.icon(onPressed: () => showAdminDeleteDialog(context, name: 'Сообщение чата', onDelete: () async { ref.invalidate(chatLogsProvider); }), icon: const Icon(Icons.delete, size: 12, color: adminDanger), label: const Text('Удалить', style: TextStyle(fontSize: 10, color: adminDanger))),
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
        TextButton.icon(onPressed: () => showAdminBulkActionDialog(context, title: 'Удалить', message: 'Удалить выбранные сообщения?', selectedCount: _selectedIds.length, onConfirm: () async { _selectedIds.clear(); }), icon: const Icon(Icons.delete, size: 14, color: adminDanger), label: const Text('Удалить', style: TextStyle(color: adminDanger, fontSize: 11))),
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
