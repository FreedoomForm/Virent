import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class BonusesPage extends ConsumerWidget {
  const BonusesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bonusesListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e", style: const TextStyle(color: Colors.red))),
      data: (items) {
        return Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Бонусы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 704 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить бонусы', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B68EE),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _labeledInput('ID клиента', 150),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFF7B68EE), borderRadius: BorderRadius.circular(3)),
                          child: const Text('Компания ▼', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: 200,
                    height: 32,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Поиск:',
                        hintStyle: const TextStyle(fontSize: 11),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF8F9FA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 50, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 150, child: Text('Client', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 150, child: Text('Bonus sum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 250, child: Text('Who added', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Create time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Comment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Company', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _bonusRow('704', 'surname azamat', '15 000.00 С.', 'Call Abdukarim', '19 июн 2026, 09:34', 'Бонус', 'ViRent'),
                      _bonusRow('703', 'surname azamat', '10 000.00 С.', 'Call Sirojiddin', '19 июн 2026, 06:26', '', 'ViRent'),
                      _bonusRow('702', 'surname Нозимбек', '9 000.00 С.', 'Call Sirojiddin', '19 июн 2026, 01:05', '', 'ViRent'),
                      _bonusRow('701', 'surname abduvoris', '-15 000.00 С.', 'Call Abdukarim', '18 июн 2026, 17:39', '', 'ViRent'),
                      _bonusRow('700', 'surname Adxam', '15 000.00 С.', 'Call Abdukarim', '18 июн 2026, 17:12', '', 'ViRent'),
                      _bonusRow('699', 'surname abduvoris', '15 000.00 С.', 'Call Abdukarim', '18 июн 2026, 16:53', '', 'ViRent'),
                      _bonusRow('698', 'surname malik', '14 900.00 С.', 'Call Abdukarim', '15 июн 2026, 08:05', 'Бонус', 'ViRent'),
                      _bonusRow('697', 'surname Bobur', '35 000.00 С.', 'ViRent Шерзод А...ов', '15 июн 2026, 04:46', '', 'ViRent'),
                      _bonusRow('696', 'surname jony', '24 900.00 С.', 'Call Abdukarim', '13 июн 2026, 05:05', '', 'ViRent'),
                      _bonusRow('695', 'surname Саид', '34 900.00 С.', 'Call Oybek', '13 июн 2026, 03:07', '', 'ViRent'),
                      _bonusRow('694', 'surname даша', '14 900.00 С.', 'Call Abdukarim', '13 июн 2026, 01:00', 'Бонус', 'ViRent'),
                      _bonusRow('693', 'surname Амир', '4 050.00 С.', 'Call Sirojiddin', '10 июн 2026, 01:53', 'Бонус', 'ViRent'),
                      _bonusRow('692', 'surname михаил', '50 000.00 С.', 'ViRent Шерзод А...ов', '08 июн 2026, 23:45', '', 'ViRent'),
                      _bonusRow('691', 'surname исмаил', '24 900.00 С.', 'Call Oybek Mozirov', '08 июн 2026, 03:13', '', 'ViRent'),
                      _bonusRow('690', 'surname maf', '14 900.00 С.', 'Call Oybek Mozirov', '08 июн 2026, 02:25', '', 'ViRent'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      };
    },
);
  }

  Widget _bonusRow(String id, String client, String sum, String whoAdded, String created, String comment, String company) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(client, style: const TextStyle(fontSize: 11, color: Color(0xFF3498DB)))),
          SizedBox(width: 150, child: Text(sum, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 250, child: Text(whoAdded, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 200, child: Text(created, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 200, child: Text(comment, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(company, style: const TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  Widget _labeledInput(String label, double width) {
    return Row(
      children: [
        SizedBox(
          width: width,
          height: 28,
          child: TextField(
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            style: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(onTap: () {}, child: Icon(Icons.close, size: 14, color: Colors.grey[500])),
      ],
    );
  }
}
