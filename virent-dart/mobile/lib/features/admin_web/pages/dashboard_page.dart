import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Панель управления',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal),
          ),
          const SizedBox(height: 24),
          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
            data: (stats) => _buildDashboard(context, stats),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> stats) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatsGrid(context, stats),
              const SizedBox(height: 24),
              _buildListsSection(stats),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildControlPanel(),
              const SizedBox(height: 24),
              _buildPushPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> s) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _statCard(context, 'Всего', s['total'], const Color(0xFF1B2032)),
        _statCard(context, 'На линии', s['online'], const Color(0xFF16A085)),
        _statCard(context, 'Не на линии', s['offline'], const Color(0xFFF39C12)),
        _statCard(context, 'На складе', s['in_warehouse'], const Color(0xFFF1C40F)),
        _statCard(context, 'В техничке', s['in_service'], const Color(0xFFF5D76E)),
        _statCard(context, 'Свободно', s['free'], const Color(0xFF5DADE2)),
        _statCard(context, 'Бронь', s['booked'], const Color(0xFF1ABC9C)),
        _statCard(context, 'В аренде', s['in_ride'], const Color(0xFF8E44AD)),
        _statCard(context, 'Онлайн', s['online'], const Color(0xFF2ECC71)),
        _statCard(context, 'Не онлайн', s['offline'], const Color(0xFFD9534F)),
      ],
    );
  }

  Widget _statCard(BuildContext context, String title, dynamic value, Color bgColor) {
    final display = value?.toString() ?? '0';
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              child: Container(
                width: 400,
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Детальная информация появится здесь', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black, elevation: 0),
                          child: const Text('Close'),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Container(
        width: 220,
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
            Text(display, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildListsSection(Map<String, dynamic> s) {
    final tariffs = (s['tariffs_in_use'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final abonements = (s['abonements_in_use'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildListCard('Тарифы в аренде', tariffs)),
        const SizedBox(width: 16),
        Expanded(child: _buildListCard('Абонементы в аренде', abonements)),
      ],
    );
  }

  Widget _buildListCard(String title, List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7B68EE),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 16),
          ...items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text((item['title'] ?? item['name'] ?? '').toString(), style: const TextStyle(color: Colors.white)),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: Text((item['count'] ?? item['value'] ?? '0').toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    )
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Управление'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E44AD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Обновление'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF39C12),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Режим техника'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton('опубликовать', const Color(0xFF1ABC9C)),
                _buildActionButton('снять с публикации', const Color(0xFFBDC3C7)),
                _buildActionButton('редактировать', const Color(0xFF3498DB)),
                _buildActionButton('статус', const Color(0xFFF1C40F)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_drop_down),
              label: const Text('Сообщения пользователю по событиям'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B68EE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(onPressed: () {}, child: const Text('Выключить аренды')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () {}, child: const Text('Получить клиентов')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPushPanel() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('PUSH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Заголовок'),
            const SizedBox(height: 8),
            const TextField(decoration: InputDecoration(border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 16),
            const Text('Сообщение'),
            const SizedBox(height: 8),
            const TextField(decoration: InputDecoration(border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(onPressed: null, child: const Text('PUSH')),
                OutlinedButton(onPressed: null, child: const Text('РЕКОМЕНДАЦИИ ПО PUSH')),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Прервать выполнение', style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(label),
    );
  }
}
