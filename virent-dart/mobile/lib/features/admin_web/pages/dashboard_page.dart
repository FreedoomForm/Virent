import '../widgets/admin_table_page.dart' show adminPrimaryColor, adminPrimaryForeground;
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Stats and Lists)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatsGrid(context, statsAsync),
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
                    _buildControlPanel(context, ref),
                    const SizedBox(height: 24),
                    _buildPushPanel(context, ref),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 120,
        child: Center(child: Text('Ошибка: $e', style: const TextStyle(color: Colors.red))),
      ),
      data: (stats) {
        int _n(String key) {
          final v = stats[key];
          if (v == null) return 0;
          if (v is int) return v;
          if (v is num) return v.toInt();
          return int.tryParse(v.toString()) ?? 0;
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(context, 'Всего', '${_n('total')}', const Color(0xFF1B2032)),
            _buildStatCard(context, 'На линии', '${_n('online')}', const Color(0xFF16A085)),
            _buildStatCard(context, 'Не на линии', '${_n('offline')}', const Color(0xFFF39C12)),
            _buildStatCard(context, 'На складе', '${_n('warehouse')}', const Color(0xFFF1C40F)),
            _buildStatCard(context, 'В техничке', '${_n('service')}', const Color(0xFFF5D76E)),
            _buildStatCard(context, 'Свободно', '${_n('free')}', const Color(0xFF5DADE2)),
            _buildStatCard(context, 'Бронь', '${_n('reserved')}', const Color(0xFF1ABC9C)),
            _buildStatCard(context, 'В аренде', '${_n('in_rent')}', const Color(0xFF8E44AD)),
            _buildStatCard(context, 'Онлайн', '${_n('online_total')}', const Color(0xFF2ECC71)),
            _buildStatCard(context, 'Не онлайн', '${_n('offline_total')}', const Color(0xFFD9534F)),
          ],
          // ── Revenue chart ──
          const SizedBox(height: 16),
          _buildRevenueChart(context, stats),
        );
      },
    );
  }

  Widget _buildRevenueChart(BuildContext context, Map<String, dynamic> stats) {
    final revenue = (stats['revenue'] ?? stats['revenue_today'] ?? 0) is num
        ? (stats['revenue'] as num).toDouble()
        : 0.0;
    final trips = (stats['trips'] ?? stats['trips_count'] ?? stats['total_trips'] ?? 0) is num
        ? (stats['trips'] as num).toInt()
        : 0;
    final scooters = (stats['scooters'] ?? stats['scooters_total'] ?? stats['total'] ?? 0) is num
        ? (stats['scooters'] as num).toInt()
        : 0;
    final users = (stats['users'] ?? stats['users_total'] ?? stats['total_users'] ?? 0) is num
        ? (stats['users'] as num).toInt()
        : 0;
    final utilization = scooters > 0 ? ((stats['online'] ?? 0) is num
        ? ((stats['online'] as num).toInt() / scooters * 100).round()
        : 0) : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Сводка', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          // Revenue row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Доход сегодня', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text('${revenue.toInt().toString()} сум',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF16A085))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Поездок', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text('$trips', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Utilization bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Флот на линии', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('$utilization% ($scooters самокатов)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: utilization / 100,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF2ECC71)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Users row
          Row(children: [
            _miniStat('👤', 'Пользователи', '$users'),
            const SizedBox(width: 16),
            _miniStat('🛴', 'Самокаты', '${(stats['online'] ?? stats['online_total'] ?? 0) is num ? (stats['online'] as num).toInt() : 0} онлайн'),
          ]),
        ],
      ),
    );
  }

  Widget _miniStat(String emoji, String label, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 4),
      Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
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
        color: adminPrimaryColor,
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
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['title']!, style: const TextStyle(color: Colors.white)),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      child: Text(item['count']!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    )
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, WidgetRef ref) {
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
                  onPressed: () => showAdminInfoDialog(
                      context, 'Обновление', 'Запущен процесс обновления'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E44AD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Обновление'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => showAdminInfoDialog(
                      context, 'Режим техника', 'Режим техника включен'),
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
                _buildActionButton(context, 'опубликовать', const Color(0xFF1ABC9C),
                    () => showAdminSnack(context, 'Опубликовано')),
                _buildActionButton(context, 'снять с публикации', const Color(0xFFBDC3C7),
                    () => showAdminSnack(context, 'Снято с публикации')),
                _buildActionButton(context, 'редактировать', const Color(0xFF3498DB),
                    () => showAdminSnack(context, 'Режим редактирования')),
                _buildActionButton(context, 'статус', const Color(0xFFF1C40F),
                    () => showAdminSnack(context, 'Статус загружен')),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => showAdminInfoDialog(context,
                  'Сообщения по событиям', 'Открыт редактор сообщений по событиям'),
              icon: const Icon(Icons.arrow_drop_down),
              label: const Text('Сообщения пользователю по событиям'),
              style: ElevatedButton.styleFrom(
                backgroundColor: adminPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => showAdminConfirmDialog(
                    context,
                    title: 'Выключить аренды',
                    message: 'Выключить все аренды на время? Активные поездки будут завершены.',
                    confirmLabel: 'Выключить',
                    successMessage: 'Аренды выключены',
                    confirmColor: Colors.orange,
                    onConfirm: () async {
                      ref.invalidate(dashboardStatsProvider);
                      ref.invalidate(tripsListProvider);
                      ref.invalidate(scootersListProvider);
                    },
                  ),
                  child: const Text('Выключить аренды'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    ref.invalidate(customersListProvider);
                    showAdminSnack(context, 'Список клиентов обновлён');
                  },
                  child: const Text('Получить клиентов'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPushPanel(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
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
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 16),
            const Text('Сообщение'),
            const SizedBox(height: 8),
            TextField(
              controller: bodyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    final body = bodyCtrl.text.trim();
                    if (title.isEmpty || body.isEmpty) {
                      showAdminSnack(context, 'Введите заголовок и сообщение', isError: true);
                      return;
                    }
                    runAdminAction(
                      context,
                      () => ref.read(sendBroadcastNotificationAction)(
                            title: title,
                            body: body,
                          ),
                      successMessage: 'PUSH отправлен',
                    );
                  },
                  child: const Text('PUSH'),
                ),
                OutlinedButton(onPressed: null, child: const Text('РЕКОМЕНДАЦИИ ПО PUSH')),
                OutlinedButton(
                  onPressed: () => showAdminSnack(context, 'Прервано'),
                  child: const Text('Прервать выполнение', style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(label),
    );
  }
}
