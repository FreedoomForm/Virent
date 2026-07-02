import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';
import './widgets/admin_dialogs.dart';

class OnlineChatPage extends ConsumerWidget {
  const OnlineChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatLogsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
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
                                  Container(height: 12, color: adminWarning),
                                  const SizedBox(height: 4),
                                  Container(height: 12, color: adminDanger),
                                  const SizedBox(height: 4),
                                  Container(height: 12, color: adminSuccess),
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
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5CB85C),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    children: [
                      _clientItem('290671', '19.06.2026, 11:50', true),
                      _clientItem('296276', '19.06.2026, 10:23', true),
                      _clientItem('296587', '19.06.2026, 09:56', true),
                      _clientItem('124652', '19.06.2026, 09:25', true),
                      _clientItem('200436', '19.06.2026, 02:24', true),
                      _clientItem('53128', '19.06.2026, 01:51', true),
                      _clientItem('295443', '19.06.2026, 01:02', true),
                      _clientItem('296542', '19.06.2026, 00:19', true),
                      _clientItem('296509', '18.06.2026, 19:27', true),
                      _clientItem('296493', '18.06.2026, 15:57', true),
                      _clientItem('296431', '18.06.2026, 00:37', true),
                      _clientItem('296427', '18.06.2026, 00:23', true),
                      _clientItem('131969', '17.06.2026, 23:05', true),
                    ],
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
                        border: Border.all(color: adminTextGray),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: adminTextGray)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: adminTextGray)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5CB85C),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      },
    );
  }

  Widget _clientItem(String id, String time, bool unread) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: unread ? const Color(0xFFFBE4D5) : Colors.white,
        borderRadius: BorderRadius.circular(8),
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
