import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class OnlineChatPage extends ConsumerWidget {
  const OnlineChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFFEEEEEE),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left sidebar (clients)
          Container(
            width: 300,
            color: const Color(0xFFF0F0F0),
            child: Column(
              children: [
                // Top header
                Container(
                  color: const Color(0xFFE0E0E0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(height: 12, color: const Color(0xFFF1C40F)),
                                  const SizedBox(height: 4),
                                  Container(height: 12, color: const Color(0xFFE74C3C)),
                                  const SizedBox(height: 4),
                                  Container(height: 12, color: const Color(0xFF2ECC71)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Клиенты', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Поиск клиента...',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    fillColor: Colors.white,
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () { /* action */ },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5CB85C),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Text('Найти', style: TextStyle(color: Colors.white, fontSize: 12)),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                // Client list
                Expanded(
                  child: ref.watch(chatLogsProvider).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Ошибка: $e')),
                    data: (items) => ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      children: items.isEmpty
                        ? [const Center(child: Text('Нет активных чатов', style: TextStyle(color: Colors.grey)))]
                        : items.map((item) => _clientItem(
                            item['client_id']?.toString() ?? '',
                            item['last_message_time']?.toString() ?? '',
                            item['unread'] == true || item['unread'] == 1,
                          )).toList(),
                    ),
                  ),
                )
              ],
            ),
          ),
          // Middle chat area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Введите сообщение...',
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade400)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade400)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () { /* action */ },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5CB85C),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('Отправить', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          // Right sidebar (notifications)
          Container(
            width: 250,
            color: const Color(0xFFF0F0F0),
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Уведомления', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _clientItem(String id, String time, bool unread) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: unread ? const Color(0xFFFBE4D5) : Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Клиент $id', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 12, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(time, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  )
                ],
              ),
            ],
          ),
          const Icon(Icons.more_horiz, size: 16, color: Colors.black54),
        ],
      ),
    );
  }
}
