// trip_receipt_screen.dart — Trip receipt / квитанция поездки.
//
// Shows a detailed cost breakdown after ride end or from history.
// Designed for screenshot/sharing — no external dependencies.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/theme/app_colors.dart';

class TripReceiptScreen extends ConsumerWidget {
  const TripReceiptScreen({super.key, this.tripId});

  final String? tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Demo receipt data — in production, fetch from /trips/:id
    final receipt = _demoReceipt;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Квитанция'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Receipt card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo / header
                  const Icon(Icons.electric_scooter, size: 48, color: AppColors.primary),
                  const SizedBox(height: 12),
                  const Text('VIRENT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text('Поездка #${receipt['id']}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text(receipt['date']!, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  const SizedBox(height: 24),

                  // Map route placeholder
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.route, size: 32, color: AppColors.primary),
                          SizedBox(height: 4),
                          Text('Маршрут поездки', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ride stats
                  _statRow('🛴 Самокат', receipt['scooter']!),
                  _statRow('⏱️ Длительность', receipt['duration']!),
                  _statRow('📏 Расстояние', receipt['distance']!),
                  const Divider(height: 24),

                  // Cost breakdown
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Детализация', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  const SizedBox(height: 8),
                  _costRow('Тариф (базовый)', receipt['base_fare']!, Colors.black87),
                  _costRow('Поминутно (${receipt['minutes']} мин)', receipt['minute_cost']!, Colors.black87),
                  if ((receipt['zone_surcharge'] as num) > 0)
                    _costRow('Надбавка зоны', receipt['zone_surcharge']!, Colors.orange),
                  if ((receipt['promo_discount'] as num) > 0)
                    _costRow('Промокод (скидка)', '-${receipt['promo_discount']}', Colors.green),
                  const Divider(height: 16),
                  _costRow('ИТОГО', receipt['total']!, AppColors.primary, bold: true),

                  const SizedBox(height: 24),

                  // Share / download buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Квитанция сохранена'), behavior: SnackBarBehavior.floating),
                            );
                          },
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Скачать'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ссылка скопирована'), behavior: SnackBarBehavior.floating),
                            );
                          },
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('Поделиться'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Footer
            Text('Спасибо за поездку! 🛴', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text('virent.io', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _costRow(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(value,
              style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  static const _demoReceipt = <String, dynamic>{
    'id': '24231487',
    'date': '23 июня 2026, 14:32',
    'scooter': 'Virent #42',
    'duration': '18 мин',
    'distance': '3.2 км',
    'minutes': '18',
    'base_fare': '5 000 сум',
    'minute_cost': '10 800 сум',
    'zone_surcharge': 0,
    'promo_discount': 0,
    'total': '15 800 сум',
  };
}
