import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(dashboardStatsProvider);

    return asyncItems.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: \$e', style: const TextStyle(color: Colors.red))),
      data: (items) => SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Панель управления',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Stats and Lists)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatsGrid(context),
                    const SizedBox(height: 24),
                    _buildListsSection(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right Column (Controls & Forms)
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
          ),
        ],
      ),
    );
  }

  Widget_buildStatsGrid(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard(context, 'Всего', '300', const Color(0xFF1B2032)),
        _buildStatCard(context, 'На линии', '241', const Color(0xFF16A085)),
        _buildStatCard(context, 'Не на линии', '59', const Color(0xFFF39C12)),
        _buildStatCard(context, 'На складе', '1', const Color(0xFFF1C40F)),
        _buildStatCard(context, 'В техничке', '50', const Color(0xFFF5D76E)),
        _buildStatCard(context, 'Свободно', '237', const Color(0xFF5DADE2)),
        _buildStatCard(context, 'Бронь', '0', const Color(0xFF1ABC9C)),
        _buildStatCard(context, 'В аренде', '4', const Color(0xFF8E44AD)),
        _buildStatCard(context, 'Онлайн', '268', const Color(0xFF2ECC71)),
        _buildStatCard(context, 'Не онлайн', '32', const Color(0xFFD9534F)),
      ],
    );
    );
  ),
);
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color bgColor) {
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(text: const TextSpan(children: [TextSpan(text: 'Самокат: ', style: TextStyle(color: Colors.black)), TextSpan(text: '2056', style: TextStyle(color: Colors.blue))])),
                          const SizedBox(height: 4),
                          RichText(text: const TextSpan(children: [TextSpan(text: 'Самокат: ', style: TextStyle(color: Colors.black)), TextSpan(text: '2060', style: TextStyle(color: Colors.blue))])),
                          const SizedBox(height: 4),
                          RichText(text: const TextSpan(children: [TextSpan(text: 'Самокат: ', style: TextStyle(color: Colors.black)), TextSpan(text: '624', style: TextStyle(color: Colors.blue))])),
                          const SizedBox(height: 4),
                          RichText(text: const TextSpan(children: [TextSpan(text: 'Самокат: ', style: TextStyle(color: Colors.black)), TextSpan(text: '940', style: TextStyle(color: Colors.blue))])),
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
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildListsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildListCard('Тарифы в аренде', [
          {'title': 'Минутный ИП Асилбеков', 'count': '3'},
          {'title': 'Для 30мин ИП Асилбеков', 'count': '1'},
        ])),
        const SizedBox(width: 16),
        Expanded(child: _buildListCard('Абонементы в аренде', [
          {'title': '30 Мин ИП Асилбеков', 'count': '1'},
        ])),
      ],
    );
  }

  Widget _buildListCard(String title, List<Map<String, String>> items) {
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
                    Text(item['title']!, style: const TextStyle(color: Colors.white)),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: Text(item['count']!, style: const TextStyle(color: Colors.white, fontSize: 12)),
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