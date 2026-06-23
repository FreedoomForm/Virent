import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(analyticsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Статистика', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.black, elevation: 0),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
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
          asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
            data: (data) => _buildStatsContent(data),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          childAspectRatio: 2,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _statCard((data['avg_trip_duration'] ?? data['avg_duration'] ?? '0').toString() + ' мин.', 'Средняя продолжительность поездки', const Color(0xFF4A81D4)),
            _statCard((data['active_clients'] ?? data['repeat_clients'] ?? '0').toString(), 'Количество клиентов ≥ 2 поездок', const Color(0xFF4FC1E9)),
            _statCard((data['revenue'] ?? data['income'] ?? '0').toString() + ' C.', 'Доход за период', const Color(0xFFFFCE54)),
            _statCard((data['total_rides'] ?? data['rides_count'] ?? '0').toString(), 'Количество аренд за период', const Color(0xFFDA4453)),
            _statCard((data['inactive_rides'] ?? data['inactive_count'] ?? '0').toString(), 'Количество неактивных аренд за период', const Color(0xFFFFCE54)),
            _statCard((data['avg_check'] ?? data['average_receipt'] ?? '0').toString(), 'Средний чек за период', const Color(0xFF4A81D4)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _sectionCard('Количество заказов в абонементе', (data['abonement_orders'] ?? data['abonement_count'] ?? '0').toString(), const Color(0xFF37BC9B))),
            const SizedBox(width: 16),
            Expanded(child: _sectionCard('Количество заказов в тарифе', (data['tariff_orders'] ?? data['tariff_count'] ?? '0').toString(), const Color(0xFF37BC9B))),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF4FC1E9), borderRadius: BorderRadius.circular(4)),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ИП Асилбеков Шерзод', child: Text('ИП Асилбеков Шерзод')),
                      ],
                      onChanged: (val) {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
                    onPressed: () {},
                    child: const Text('Показать'),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Text((data['invoice_revenue'] ?? data['account_income'] ?? '0').toString() + ' C.', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, String content, Color color) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
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
            color: color.withOpacity(0.9),
            child: Text(content, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
