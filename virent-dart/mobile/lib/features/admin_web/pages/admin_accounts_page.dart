import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class AdminAccountsPage extends ConsumerWidget {
  const AdminAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
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
                        Text('Админы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 34 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить админа', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B68EE),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _roleFilter('Админ', true),
                        const SizedBox(width: 8),
                        _roleFilter('Техник', false, isYellow: true),
                        const SizedBox(width: 8),
                        _roleFilter('Партнер', false),
                        const SizedBox(width: 8),
                        _roleFilter('Оператор', false),
                        const SizedBox(width: 8),
                        _roleFilter('Helper', false),
                        const SizedBox(width: 8),
                        _roleFilter('Техник', false),
                        const SizedBox(width: 8),
                        _roleFilter('Оператор', false),
                        const SizedBox(width: 8),
                        _roleFilter('Бехзод', false),
                        const SizedBox(width: 8),
                        const Text('Дополнительные разрешения ▼', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                      SizedBox(width: 60, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 250, child: Text('Имя', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Почта', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 80, child: Text('UTC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Роли', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _adminRow('27', 'toGo Viktor', '+Mag1c_MAn1pulAtOr@yandex.ru', '5', 'Админ, Техник, Партнер, Оператор, Helper, Техник, Оператор, Бехзод'),
                      _adminRow('99', 'toGO Наталья Борисенко', 'R3v3ngg_Mts3r@bk.ru', '5', 'Админ, Техник, Партнер, Оператор, Helper, Техник, Оператор'),
                      _adminRow('278', 'toGO Nikita', 'C^yber\$PuIse@gmail.com', '5', 'Админ, Техник, Партнер, Оператор, Helper, Техник, Оператор, Бехзод'),
                      _adminRow('284', 'toGO Крушевский Егор', 'T3ch!Ninj@icloud.com', '5', 'Админ, Техник, Партнер, Оператор, Helper, Техник, Оператор, Бехзод'),
                      _adminRow('285', 'toGO Дмитрий Харитонов', 'Qu&ntum#X@gmail.com', '5', 'Техник, Партнер, Оператор, Helper, Техник, Оператор'),
                      _adminRow('291', 'ViRent-Велесик Виктор', 'toostart2020@mail.ru', '5', '-'),
                      _adminRow('317', 'ViRent Шерзод Асилбеков', 'e-motion-uz@gmail.com', '5', '-'),
                      _adminRow('318', 'ViRent Наиль Хасибулов', 'nailamirkhanov192@gmail.com', '5', '-'),
                      _adminRow('443', 'Ali Dexqonov', 'whilescooter@gmail.com', '5', '-'),
                      _adminRow('474', 'ViRent-Дмитрий Велесик', 'velesikd@gmail.com', '', 'Техник, Техник, Оператор'),
                      _adminRow('476', 'toGO Алексей', '%Pr0ph3t_Of_D00m@gmail.com', '', 'Админ, Техник, Партнер, Оператор, Helper, Техник, Оператор, Бехзод'),
                      _adminRow('477', 'CALL Аброров Сардор Дониёр ўғли Г.О', 'abrotov57@gmail.com', '', '-'),
                      _adminRow('478', 'CALL Хамидуллаев Жавoҳир Акром ўғли О', 'javahirxamidullaev337@gmail.com', '', '-'),
                      _adminRow('479', 'Call Qudratilla', 'kudratbaniyazov@gmail.ru', '', '-'),
                      _adminRow('480', 'Call Azamat', 'azamat11mirhoshimov@gmail.com', '', '-'),
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

  Widget _adminRow(String id, String name, String email, String utc, String roles) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 60, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 250, child: Text(name, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 200, child: Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE)))),
          SizedBox(width: 80, child: Text(utc, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(roles, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                InkWell(onTap: () {}, child: const Row(children: [Icon(Icons.edit, size: 12, color: Color(0xFF3498DB)), SizedBox(width: 4), Text('Редактировать', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB)))])),
                const SizedBox(width: 12),
                InkWell(onTap: () {}, child: const Row(children: [Icon(Icons.delete, size: 12, color: Color(0xFF3498DB)), SizedBox(width: 4), Text('Удалить', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB)))])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleFilter(String text, bool isSelected, {bool isYellow = false}) {
    final borderColor = isSelected ? const Color(0xFF2ECC71) : (isYellow ? const Color(0xFFF1C40F) : Colors.transparent);
    final textColor = isSelected ? const Color(0xFF2ECC71) : (isYellow ? const Color(0xFFF1C40F) : const Color(0xFF666666));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: textColor)),
    );
  }
}
