import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardStatsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
        return Container(
      color: const Color(0xFFFFFFFF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Панель управления',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF1B2A4E)),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Stats + Lists
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildStatsGrid(context),
                      const SizedBox(height: 20),
                      _buildRentalLists(),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right: Control + Push
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildControlPanel(),
                      const SizedBox(height: 20),
                      _buildPushPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Column(
      children: [
        // Row 1: Всего, На линии, Не на линии
        Row(
          children: [
            _statCard('Всего', '300', const Color(0xFF1B2A4E)),
            const SizedBox(width: 12),
            _statCard('На линии', '241', const Color(0xFF42BA96)),
            const SizedBox(width: 12),
            _statCard('Не на линии', '59', const Color(0xFF868686)),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: На складе, В техничке, Свободно
        Row(
          children: [
            _statCard('На складе', '1', const Color(0xFFFFC107)),
            const SizedBox(width: 12),
            _statCard('В техничке', '50', const Color(0xFFFFC107)),
            const SizedBox(width: 12),
            _statCard('Свободно', '237', const Color(0xFF467FD0)),
          ],
        ),
        const SizedBox(height: 12),
        // Row 3: Бронь, В аренде, Онлайн
        Row(
          children: [
            _statCard('Бронь', '0', const Color(0xFF42BA96)),
            const SizedBox(width: 12),
            _statCard('В аренде', '4', const Color(0xFF7C69EF)),
            const SizedBox(width: 12),
            _statCard('Онлайн', '268', const Color(0xFF42BA96)),
          ],
        ),
        const SizedBox(height: 12),
        // Row 4: Не онлайн
        Row(
          children: [
            _statCard('Не онлайн', '32', const Color(0xFFDF4759)),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w400)),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalLists() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Тарифы в аренде
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C69EF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Тарифы в аренде', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                _rentalRow('Минутный ИП Асилбеков', '3'),
                const SizedBox(height: 6),
                _rentalRow('Для 30мин ИП Асилбеков', '1'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Абонементы в аренде
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C69EF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Абонементы в аренде', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                _rentalRow('30 Мин ИП Асилбеков', '1'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _rentalRow(String label, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))),
          CircleAvatar(
            radius: 11,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFD9E2EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Управление', style: TextStyle(fontSize: 14, color: Color(0xFF1B2A4E))),
          const SizedBox(height: 12),
          Row(
            children: [
              _colorButton('Обновление', const Color(0xFF7C69EF)),
              const SizedBox(width: 8),
              _colorButton('Режим техника', const Color(0xFFFFC107)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
              contentPadding: const EdgeInsets.all(10),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _colorButton('опубликовать', const Color(0xFF42BA96)),
              _colorButton('снять с публикации', const Color(0xFFD9E2EF), textColor: Colors.black54),
              _colorButton('редактировать', const Color(0xFF467FD0)),
              _colorButton('статус', const Color(0xFFFFC107), textColor: Colors.black87),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7C69EF),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Row(
              children: [
                Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Expanded(child: Text('Сообщения пользователю по событиям', style: TextStyle(color: Colors.white, fontSize: 12))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFFD9E2EF)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Выключить аренды', style: TextStyle(color: Colors.black54)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFC107)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Получить клиентов', style: TextStyle(color: Color(0xFFFFC107))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPushPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFD9E2EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PUSH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4E))),
          const SizedBox(height: 12),
          const Text('Заголовок', style: TextStyle(fontSize: 12, color: Color(0xFF868686))),
          const SizedBox(height: 4),
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Text('Сообщение', style: TextStyle(fontSize: 12, color: Color(0xFF868686))),
          const SizedBox(height: 4),
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: const Text('PUSH'),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: const Text('РЕКОМЕНДАЦИИ ПО PUSH'),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: const Text('Прервать выполнение', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorButton(String label, Color color, {Color textColor = Colors.white}) {
    return ElevatedButton(
      onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }
}
