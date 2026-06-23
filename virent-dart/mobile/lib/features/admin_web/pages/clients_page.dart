import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';


class ClientsPage extends ConsumerWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customersListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
      data: (items) Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('Клиенты', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                    SizedBox(width: 12),
                    Text('Показано 1 до 20 из 129 совпадений (отфильтровано из 296,496 совпадений)',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Добавить Клиента'),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('ID клиента', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      const SizedBox(width: 4),
                      _input(100),
                      const SizedBox(width: 4),
                      _closeIcon(),
                      const SizedBox(width: 8),
                      const Text('Телефон', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      const SizedBox(width: 4),
                      _input(120),
                      const SizedBox(width: 12),
                      _chip('Группы ▼', const Color(0xFF7B68EE)),
                      _chip('Компании ▼', const Color(0xFF7B68EE)),
                      _chip('Активн.', const Color(0xFF3498DB)),
                      _chip('Не активн.', const Color(0xFFE74C3C)),
                      _chip('Заблокировать', const Color(0xFF9B59B6)),
                      _chip('Не заблокирован', const Color(0xFF2ECC71)),
                      _chip('Есть БК', const Color(0xFF1ABC9C)),
                      _chip('Нет БК', const Color(0xFFE67E22)),
                      const SizedBox(width: 8),
                      const Text('Комментарий', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      const SizedBox(width: 4),
                      _input(120),
                      const SizedBox(width: 4),
                      _closeIcon(),
                      const SizedBox(width: 8),
                      _chip('Очистить фильтры', const Color(0xFF7B68EE)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1500,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 70, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Phone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Данные клиента', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('N bonus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Debt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Cur order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 70, child: Text('Blocked', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 50, child: Text('БК', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 70, child: Text('Groups', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 130, child: Text('Comment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _clientRow('152819', '998977033902', 'Full name', '0.00 С.', false, false, ''),
                          _clientRow('153261', '998333808037', 'Full name', '0.00 С.', false, false, ''),
                          _clientRow('153281', '998947993529', 'Full name', '0.00 С.', false, false, ''),
                          _clientRow('153913', '998901057905', 'Full name', '0.00 С.', true, false, 'ошибка не бл...'),
                          _clientRow('154103', '998991271343', 'Full name', '0.00 С.', false, false, ''),
                          _clientRow('154237', '998907252522', 'Full name', '0.00 С.', false, false, ''),
                          _clientRow('154464', '998997316906', 'Full name', '0.00 С.', false, false, ''),
                          _clientRow('154495', '998900173291', 'Full name', '0.00 С.', false, false, ''),
                          _clientRow('154545', '#998903566044', 'Full name', '0.00 С.', true, false, 'Клиент удалё...'),
                          _clientRow('154571', '998949995888', 'Full name', '0.00 С.', false, false, ''),
                          _clientRow('154590', '998933404509', 'Full name', '0.00 С.', false, false, ''),
                          _clientRow('154595', '998900970013', 'Full name', '0.00 С.', true, false, ''),
                          _clientRow('155097', '998979298338', 'Full name', '0.00 С.', true, false, 'не трогайте'),
                          _clientRow('155191', '998942591700', 'Full name', '0.00 С.', false, false, ''),
                          _clientRow('155218', '998904794872', 'Full name', '0.00 С.', true, false, 'ошибка когда'),
                        ],
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
  }

  static Widget _clientRow(String id, String phone, String data, String debt, bool active, bool blocked, String comment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 120, child: Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFFE67E22)))),
          SizedBox(
            width: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF555555), borderRadius: BorderRadius.circular(2)),
              child: Text(data, style: const TextStyle(fontSize: 10, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 80),
          SizedBox(width: 80, child: Text(debt, style: const TextStyle(fontSize: 11))),
          const SizedBox(width: 80),
          SizedBox(width: 60, child: Icon(active ? Icons.check_box : Icons.check_box_outline_blank, size: 16, color: active ? Colors.green : Colors.grey.shade400)),
          SizedBox(width: 70, child: Icon(blocked ? Icons.check_box : Icons.check_box_outline_blank, size: 16, color: blocked ? Colors.red : Colors.grey.shade400)),
          SizedBox(width: 50, child: Icon(Icons.videocam, size: 14, color: Colors.purple.shade300)),
          const SizedBox(width: 70, child: Text('-', style: TextStyle(fontSize: 11))),
          SizedBox(
            width: 130,
            child: comment.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF7B68EE), borderRadius: BorderRadius.circular(2)),
                    child: Text(comment, style: const TextStyle(fontSize: 9, color: Colors.white), overflow: TextOverflow.ellipsis),
                  )
                : const SizedBox(),
          ),
          Expanded(
            child: Row(
              children: [
                InkWell(onTap: () {}, child: const Icon(Icons.people, size: 14, color: Colors.grey)),
                const SizedBox(width: 8),
                InkWell(onTap: () {}, child: const Text('Статус', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB)))),
                const SizedBox(width: 8),
                InkWell(onTap: () {}, child: const Text('Редактировать', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _input(double w) {
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

  static Widget _closeIcon() {
    return InkWell(onTap: () {}, child: Icon(Icons.close, size: 14, color: Colors.grey[500]));
  }

  static Widget _chip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  )
  }
}
