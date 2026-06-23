import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class LogsActionHistoryPage extends ConsumerWidget {
  const LogsActionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('История Действий', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 10,000 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statusFilter('Действия с БД', true),
                        const SizedBox(width: 8),
                        _statusFilter('Действие с самокатом', false, isYellow: true),
                        const SizedBox(width: 8),
                        _statusFilter('Действие с заказом', false),
                        const SizedBox(width: 8),
                        _statusFilter('Блокировка самоката', false),
                        const SizedBox(width: 8),
                        _statusFilter('Разблокировка самоката', false),
                        const SizedBox(width: 8),
                        _statusFilter('Открытие отсека батареи', false),
                        const SizedBox(width: 8),
                        const Text('...'), // ellipsis for other options to save space
                      ],
                    ),
                    const SizedBox(height: 12),
                    _labeledInput('ID пользователя', 150),
                  ],
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: 200,
                    height: 32,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Поиск:',
                        hintStyle: const TextStyle(fontSize: 11),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF8F9FA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 80, child: Text('Объект', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('ID пользователя', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Что изменено', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 150, child: Text('columns.activity_log.time_create', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  ref.watch(auditLogProvider).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Ошибка: $e")),
                    data: (items) => ListView(
                      children: items.map((item) => _actionRowFromItem(item)).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(String objectId, String userEmail, String key, String newVal, String oldVal, String date, {bool isTech = false}) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(left: 16, top: 16), child: SizedBox(width: 80, child: Text(objectId, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE))))),
          Padding(
            padding: const EdgeInsets.only(left: 0, top: 16),
            child: SizedBox(
              width: 200,
              child: isTech
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF3498DB), borderRadius: BorderRadius.circular(2)),
                          child: const Text('Техничка', style: TextStyle(color: Colors.white, fontSize: 8)),
                        ),
                        const SizedBox(width: 4),
                        Text(userEmail, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE))),
                      ],
                    )
                  : const SizedBox(),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade200), left: BorderSide(color: Colors.grey.shade200))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                          child: const Text('Key', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Text(key, style: const TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              const Icon(Icons.info_outline, size: 12, color: Color(0xFF3498DB)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade200))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                          child: const Text('New', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        Container(padding: const EdgeInsets.all(8), child: Text(newVal, style: const TextStyle(fontSize: 11))),
                      ],
                    ),
                  ),
                ),
                if (oldVal.isNotEmpty)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade200))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                            child: const Text('Old', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          Container(padding: const EdgeInsets.all(8), child: Text(oldVal, style: const TextStyle(fontSize: 11))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.only(left: 16, top: 16), child: SizedBox(width: 150, child: Text(date, style: const TextStyle(fontSize: 11)))),
        ],
      ),
    );
  }

  Widget _labeledInput(String label, double width) {
    return Row(
      children: [
        SizedBox(
          width: width,
          height: 28,
          child: TextField(
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            style: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(onTap: () {}, child: Icon(Icons.close, size: 14, color: Colors.grey[500])),
      ],
    );
  }

  Widget _statusFilter(String text, bool isSelected, {bool isYellow = false}) {
    final borderColor = isSelected ? const Color(0xFF2ECC71) : (isYellow ? const Color(0xFFF1C40F) : Colors.transparent);
    final textColor = isSelected ? const Color(0xFF2ECC71) : (isYellow ? const Color(0xFFF1C40F) : const Color(0xFF666666));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: textColor)),
    );
  }

  /// Builds a row from provider data item.
  Widget _actionRowFromItem(Map<String, dynamic> item) {
    return _actionRow(
      item['objectId']?.toString() ?? '',
      item['userEmail']?.toString() ?? '',
      item['key']?.toString() ?? '',
      item['newVal']?.toString() ?? '',
      item['oldVal']?.toString() ?? '',
      item['date']?.toString() ?? '',
      item['{bool']?.toString() ?? '',
    );
  }

}
