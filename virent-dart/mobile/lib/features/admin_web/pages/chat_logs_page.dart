import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';


class ChatLogsPage extends ConsumerWidget {
  const ChatLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatLogsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
      data: (items) => Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Сообщения', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _buildFilterInput('ID клиента', 150),
                const SizedBox(width: 8),
                _buildFilterInput('Период', 200, hint: 'Выберите даты'),
                const SizedBox(width: 8),
                _buildFilterDropdown('Администратор', 250, 'Выберите администратора'),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B68EE),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  ),
                  child: const Text('Поиск по тексту', style: TextStyle(fontSize: 12, color: Colors.white)),
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
                      SizedBox(width: 80, child: Text('client_id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('message', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 80, child: Text('image', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 100, child: Text('Answer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 140, child: Text('timestamp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 100, child: Text('Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 120, child: Text('read_by_admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 100, child: Text('read_date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 160, child: Text('Управление', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _messageRow('290671', true, false, '19.06.2026 11:50:00'),
                      _messageRow('296276', true, false, '19.06.2026 10:23:23'),
                      _messageRow('296276', true, false, '19.06.2026 10:23:10'),
                      _messageRow('296587', true, false, '19.06.2026 09:56:12'),
                      _messageRow('124652', true, false, '19.06.2026 09:25:17'),
                      _messageRow('200436', false, true, '19.06.2026 02:24:33'),
                      _messageRow('200436', true, false, '19.06.2026 02:23:56'),
                      _messageRow('53128', true, false, '19.06.2026 01:51:28'),
                      _messageRow('295443', true, false, '19.06.2026 01:02:18'),
                      _messageRow('295443', true, false, '19.06.2026 01:02:12'),
                      _messageRow('295443', true, false, '19.06.2026 01:01:41'),
                      _messageRow('296542', true, false, '19.06.2026 00:19:01'),
                      _messageRow('296509', true, false, '18.06.2026 19:27:41'),
                      _messageRow('296509', true, false, '18.06.2026 19:27:10'),
                      _messageRow('296493', true, false, '18.06.2026 15:57:37'),
                      _messageRow('296493', true, false, '18.06.2026 15:57:26'),
                      _messageRow('296276', true, false, '18.06.2026 14:33:44'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  )
  }

  Widget _buildFilterInput(String label, double width, {String hint = ''}) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), bottomLeft: Radius.circular(3)),
            ),
            child: Text(label, style: const TextStyle(fontSize: 11)),
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 11),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: const BorderRadius.only(topRight: Radius.circular(3), bottomRight: Radius.circular(3)), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: const BorderRadius.only(topRight: Radius.circular(3), bottomRight: Radius.circular(3)), borderSide: BorderSide(color: Colors.grey.shade300)),
                fillColor: Colors.white,
                filled: true,
              ),
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, double width, String hint) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), bottomLeft: Radius.circular(3)),
            ),
            child: Text(label, style: const TextStyle(fontSize: 11)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: const BorderRadius.only(topRight: Radius.circular(3), bottomRight: Radius.circular(3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(hint, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const Icon(Icons.arrow_drop_down, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageRow(String clientId, bool hasMessage, bool hasImage, String timestamp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Row(
              children: [
                Text(clientId, style: const TextStyle(fontSize: 11, color: Color(0xFF3498DB))),
                const SizedBox(width: 4),
                Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE74C3C))),
              ],
            ),
          ),
          Expanded(
            child: hasMessage
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFFFC107), borderRadius: BorderRadius.circular(3)),
                      child: const Text('Прочитать новое сообщение', style: TextStyle(fontSize: 11, color: Colors.white)),
                    ),
                  )
                : const SizedBox(),
          ),
          SizedBox(
            width: 80,
            child: hasImage ? const Icon(Icons.image, size: 20) : const SizedBox(),
          ),
          const SizedBox(width: 100),
          SizedBox(width: 140, child: Text(timestamp, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text('посмотреть', style: TextStyle(fontSize: 11, color: const Color(0xFF7B68EE).withOpacity(0.8)))),
          const SizedBox(width: 120),
          const SizedBox(width: 100),
          SizedBox(
            width: 160,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF7B68EE), borderRadius: BorderRadius.circular(3)),
                child: const Text('Написать сообщение', style: TextStyle(fontSize: 11, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
