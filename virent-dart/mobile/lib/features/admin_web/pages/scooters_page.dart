import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';


class ScootersPage extends ConsumerWidget {
  const ScootersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(scootersListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
      data: (items) => Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + count
                const Row(
                  children: [
                    Text('Самокаты', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                    SizedBox(width: 12),
                    Text('Показано 1 до 20 из 300 совпадений (отфильтровано из 663 совпадений)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                // Add button
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Добавить самокат'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B68EE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                const SizedBox(height: 10),
                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Номер', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      const SizedBox(width: 4),
                      _input(100),
                      const SizedBox(width: 4),
                      _closeIcon(),
                      const SizedBox(width: 8),
                      const Text('Комментарий', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      const SizedBox(width: 4),
                      _input(140),
                      const SizedBox(width: 4),
                      _closeIcon(),
                      const SizedBox(width: 8),
                      const Text('Батарея:', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      const SizedBox(width: 4),
                      _input(60),
                      _input(60),
                      const SizedBox(width: 4),
                      _closeIcon(),
                      const SizedBox(width: 12),
                      _chip('Модель ▼', const Color(0xFF7B68EE)),
                      _chip('Группы ▼', const Color(0xFF7B68EE)),
                      _chip('Компании ▼', const Color(0xFF7B68EE)),
                      _chip('Геозоны ▼', const Color(0xFF7B68EE)),
                      const SizedBox(width: 8),
                      _chip('Свободные', const Color(0xFFF39C12)),
                      _chip('Выключенные заказ', const Color(0xFFF39C12)),
                      _chip('Не в сети', const Color(0xFFE74C3C)),
                      _chip('В сети', const Color(0xFF2ECC71)),
                      _chip('Тревоги и откл.', const Color(0xFF1ABC9C)),
                      _chip('Тревоги и включ.', const Color(0xFF1ABC9C)),
                      _chip('Есть тревоги', const Color(0xFF1ABC9C)),
                      _chip('Нет тревог', const Color(0xFF1ABC9C)),
                      _chip('На линии', const Color(0xFF3498DB)),
                      _chip('Не на линии', const Color(0xFFE74C3C)),
                      _chip('Статус Raider', const Color(0xFF1ABC9C)),
                      _chip('Отключение АКБ', const Color(0xFFF39C12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 2200,
                child: Column(
                  children: [
                    // Header
                    Container(
                      color: const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          _hdr('ID', 40),
                          _hdr('Gosnomer', 70),
                          _hdr('Fake groups', 160),
                          _hdr('Cur order', 70),
                          _ico(Icons.wifi, 30),
                          _ico(Icons.delete, 30),
                          _ico(Icons.videocam, 30),
                          _ico(Icons.refresh, 30),
                          _ico(Icons.dark_mode, 30),
                          _ico(Icons.settings, 30),
                          _hdr('', 60), // battery icon area
                          _hdr('', 50), // speed
                          _hdr('', 60), // % bar
                          _hdr('int', 30),
                          _hdr('', 60), // Volt
                          _hdr('Режим Raider', 80),
                          _hdr('Raider Tech', 70),
                          _hdr('Alerting', 60),
                          _hdr('Внимание', 60),
                          _hdr('', 30),
                          _hdr('Company', 120),
                          _hdr('Model', 50),
                          _hdr('Geozones', 120),
                          _hdr('Действия', 200),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 15,
                        itemBuilder: (context, i) {
                          return _scooterRow(789 + i, '05-${(i + 1).toString().padLeft(4, '0')}');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  )
  }

  Widget _scooterRow(int id, String gos) {
    final isOffline = id % 5 == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('$id', style: const TextStyle(fontSize: 11))),
          SizedBox(width: 70, child: Text(gos, style: const TextStyle(fontSize: 11, color: Color(0xFFE67E22)))),
          // Fake groups - colored chips
          SizedBox(
            width: 160,
            child: Row(
              children: [
                _miniChip('на линии', Colors.green),
                const SizedBox(width: 2),
                _miniChip('на линии', Colors.blue),
                const SizedBox(width: 2),
                _miniChip('Группы', Colors.grey),
              ],
            ),
          ),
          // Cur order
          const SizedBox(width: 70),
          // Icons columns
          SizedBox(width: 30, child: Text(isOffline ? 'OFFLINE' : 'ONLINE', style: TextStyle(fontSize: 7, color: isOffline ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
          SizedBox(width: 30, child: Text(isOffline ? 'UNLOCK' : 'LOCK', style: TextStyle(fontSize: 7, color: isOffline ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
          SizedBox(width: 30, child: Text(isOffline ? 'Motion' : 'No motion', style: TextStyle(fontSize: 7, color: isOffline ? Colors.orange : Colors.grey))),
          const SizedBox(width: 30),
          const SizedBox(width: 30),
          const SizedBox(width: 30),
          // Battery
          SizedBox(width: 60, child: Text('${50 + (id % 50)} %', style: const TextStyle(fontSize: 11))),
          // Speed
          SizedBox(width: 50, child: Text('${id % 3 == 0 ? 3 : 0} км/ч', style: const TextStyle(fontSize: 11))),
          // % bar range
          SizedBox(width: 60, child: Text(isOffline ? '61-80 %' : '81-100 %', style: const TextStyle(fontSize: 11))),
          // int
          const SizedBox(width: 30, child: Text('sat', style: TextStyle(fontSize: 11))),
          // Volt
          SizedBox(width: 60, child: Text('${50000 + id * 10} V', style: const TextStyle(fontSize: 11))),
          // Raider
          const SizedBox(width: 80),
          const SizedBox(width: 70),
          // Alerting
          SizedBox(width: 60, child: Icon(Icons.check_box_outline_blank, size: 14, color: Colors.grey[400])),
          // Внимание
          SizedBox(width: 60, child: Icon(Icons.check_box_outline_blank, size: 14, color: Colors.grey[400])),
          const SizedBox(width: 30),
          // Company
          const SizedBox(width: 120, child: Text('ИП Асилбеков Шерзод', style: TextStyle(fontSize: 10))),
          const SizedBox(width: 50, child: Text('OKAI E[...]', style: TextStyle(fontSize: 10))),
          // Geozones
          const SizedBox(width: 120, child: Text('Ташкент, Зона запрета выл...', style: TextStyle(fontSize: 10))),
          // Actions
          SizedBox(
            width: 200,
            child: Row(
              children: [
                _actionLink('Просмотр'),
                _actionLink('Редактировать'),
                _actionLink('Удалить'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionLink(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {},
        child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF3498DB))),
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 8)),
    );
  }

  Widget _hdr(String label, double w) {
    return SizedBox(width: w, child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)));
  }

  Widget _ico(IconData icon, double w) {
    return SizedBox(width: w, child: Icon(icon, size: 14, color: Colors.grey[600]));
  }

  Widget _input(double w) {
    return SizedBox(
      width: w,
      height: 28,
      child: TextField(
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
        ),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _closeIcon() {
    return InkWell(onTap: () {}, child: Icon(Icons.close, size: 14, color: Colors.grey[500]));
  }

  Widget _chip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}
