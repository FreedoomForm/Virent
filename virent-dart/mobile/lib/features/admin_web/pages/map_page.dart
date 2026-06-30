import 'package:flutter/material.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Фильтры', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1B2A4E))),
                const SizedBox(height: 8),
                // Row 1: Model, Status, Groups, etc.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Модель', const Color(0xFF7C69EF)),
                      _filterChip('Статус', const Color(0xFF7C69EF)),
                      _filterChip('Группы', const Color(0xFF7C69EF)),
                      _filterChip('Свободные', const Color(0xFFFFC107)),
                      _filterChip('Выключенные заказ.', const Color(0xFF7C69EF)),
                      const SizedBox(width: 8),
                      _smallInput('Номер', 100),
                      const SizedBox(width: 4),
                      _smallInput('Телефон', 120),
                      const SizedBox(width: 4),
                      const Text('Батарея:', style: TextStyle(fontSize: 11, color: Color(0xFF868686))),
                      const SizedBox(width: 4),
                      _smallInput('От (%)', 60),
                      _smallInput('До (%)', 60),
                      const SizedBox(width: 12),
                      _filterChip('На линии', const Color(0xFF467FD0)),
                      _filterChip('Не на линии', const Color(0xFFFFC107)),
                      _filterChip('В сети', const Color(0xFF42BA96)),
                      _filterChip('Не в сети', const Color(0xFFDF4759)),
                      _filterChip('Заказ и долги', const Color(0xFF42BA96)),
                      _filterChip('Тревоги отключены', const Color(0xFF42BA96)),
                      _filterChip('Тревоги включены', const Color(0xFF42BA96)),
                      _filterChip('карта на весь экран', const Color(0xFF42BA96)),
                      _filterChip('Режим Raider', const Color(0xFFDF4759), outlined: true),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Row 2: Cities
                Row(
                  children: [
                    _filterChip('Ташкент', const Color(0xFF7C69EF)),
                    _filterChip('Самарканд', const Color(0xFF7C69EF)),
                    _filterChip('Фергана', const Color(0xFF1B2A4E)),
                  ],
                ),
              ],
            ),
          ),
          // Map type tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Текущая карта: Общая', style: TextStyle(fontSize: 13, color: Color(0xFF868686))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _tabButton('Общая карта', true),
                    _tabButton('Тепловая карта', false),
                    _tabButton('Частота аренд', false),
                    _tabButton('Группирование самокатов', false),
                  ],
                ),
              ],
            ),
          ),
          // Map placeholder + sidebar
          Expanded(
            child: Row(
              children: [
                // Map area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 0, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E0D8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFD9E2EF)),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map, size: 64, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Карта (Leaflet)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                              Text('Ташкент', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2), border: Border.all(color: Color(0xFF868686))),
                                child: const SizedBox(width: 28, height: 28, child: Center(child: Icon(Icons.add, size: 16))),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2), border: Border.all(color: Color(0xFF868686))),
                                child: const SizedBox(width: 28, height: 28, child: Center(child: Icon(Icons.remove, size: 16))),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right info panel
                Container(
                  width: 220,
                  margin: const EdgeInsets.fromLTRB(8, 0, 12, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFD9E2EF)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_box, color: Colors.blue, size: 14),
                            const SizedBox(width: 4),
                            const Text('Показывать геозоны', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._infoFields(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _infoFields() {
    final fields = ['Номер', 'Обновлено', 'Группы', 'Заказ', '', '', '', '', '', '', 'Геозоны', 'Блокировка', 'Комментарий', 'Отсек Батареи', 'Режим Raider'];
    return fields.map((f) {
      if (f.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Divider(color: Color(0xFFD9E2EF))),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1B2A4E))),
            const Divider(height: 8),
          ],
        ),
      );
    }).toList();
  }

  Widget _filterChip(String label, Color color, {bool outlined = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(3),
        border: outlined ? Border.all(color: color) : null,
      ),
      child: Text(label, style: TextStyle(color: outlined ? color : Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _smallInput(String hint, double width) {
    return SizedBox(
      width: width,
      height: 28,
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
        ),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _tabButton(String label, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF7C69EF) : Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: active ? const Color(0xFF7C69EF) : Color(0xFFD9E2EF)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: active ? Colors.white : const Color(0xFF868686))),
    );
  }
}
