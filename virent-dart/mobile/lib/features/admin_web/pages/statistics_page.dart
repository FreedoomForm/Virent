import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';
import '../widgets/admin_dialogs.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(analyticsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
        return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Статистика', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                style: ElevatedButton.styleFrom(backgroundColor: adminBorder, foregroundColor: Colors.black, elevation: 0),
                child: const Text('Табличная выгрузка'),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 250,
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_today, size: 16),
                    hintText: '19.05.26 0:00 - 19.06.26 23:59',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  value: 'ИП Асилбеков Шерзод',
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ИП Асилбеков Шерзод', child: Text('ИП Асилбеков Шерзод')),
                    DropdownMenuItem(value: 'ИП Асилбекова Нигора', child: Text('ИП Асилбекова Нигора')),
                    DropdownMenuItem(value: 'ИП Раматбоев Озод', child: Text('ИП Раматбоев Озод')),
                    DropdownMenuItem(value: 'ИП Руфатова Зухра', child: Text('ИП Руфатова Зухра')),
                  ],
                  onChanged: (val) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            childAspectRatio: 2,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard('24.25 мин.', 'Средняя продолжительность поездки', const Color(0xFF4A81D4)),
              _buildStatCard('1278', 'Количество клиентов ≥ 2 поездок', const Color(0xFF4FC1E9)),
              _buildStatCard('109984540.39 C.', 'Доход за период', const Color(0xFFFFCE54)),
              _buildStatCard('7979', 'Количество аренд за период', const Color(0xFFDA4453)),
              _buildStatCard('444', 'Количество неактивных аренд за период', const Color(0xFFFFCE54)),
              _buildStatCard('13,784.25', 'Средний чек за период', const Color(0xFF4A81D4)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSectionCard('Количество заказов в абонементе', 'Не найдено...', const Color(0xFF37BC9B))),
              const SizedBox(width: 16),
              Expanded(child: _buildSectionCard('Количество заказов в тарифе', 'Не найдено...', const Color(0xFF37BC9B))),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF4FC1E9), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Доход за период по счетам', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.calendar_today, size: 16),
                          hintText: '19.05.26 0:00 - 19.06.26 23:59',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: 'ИП Асилбеков Шерзод',
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ИП Асилбеков Шерзод', child: Text('ИП Асилбеков Шерзод')),
                        ],
                        onChanged: (val) {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: adminPrimary, foregroundColor: Colors.white),
                      onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                      child: const Text('Показать'),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                const Text('— С.', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
      },
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, String content, Color color) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: adminBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: color,
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: color.withValues(alpha: 0.9),
            child: Text(content, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
