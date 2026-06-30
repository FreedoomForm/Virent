import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';

class InspectionDamagesPage extends ConsumerWidget {
  const InspectionDamagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inspectionDamagesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
        return Container(
      color: const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('Повреждения', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 297 совпадений (отфильтровано из 156,150 совпадений)',
                            style: TextStyle(fontSize: 11, color: adminTextGray)),
                      ],
                    ),
                    SizedBox(
                      width: 200,
                      height: 32,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Поиск:',
                          hintStyle: const TextStyle(fontSize: 11),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _labeledInput('Самокат', 100),
                      const SizedBox(width: 8),
                      _labeledInput('Номер', 100),
                      const SizedBox(width: 8),
                      const Text('Конкретный день ▼', style: TextStyle(fontSize: 11, color: adminTextGray)),
                      const SizedBox(width: 8),
                      const Text('Промежуток времени ▼', style: TextStyle(fontSize: 11, color: adminTextGray)),
                      const SizedBox(width: 12),
                      _chipBtn('Парковки', adminBorder),
                      _chipBtn('Фото при начале', adminWarning),
                      _chipBtn('Фото при завершении', adminWarning),
                      const SizedBox(width: 8),
                      _chipBtn('Очистить фильтры', adminPrimary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 400, child: Text('Path', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 150, child: Text('Car', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 150, child: Text('Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _damageRow('05-792', '76919[...]', 'Завершение'),
                      _damageRow('05-742', '76920[...]', 'Завершение'),
                      _damageRow('05-0114', '76919[...]', 'Завершение'),
                      _damageRow('05-0090', '76919[...]', 'Завершение'),
                      _damageRow('05-714', '76919[...]', 'Завершение'),
                      _damageRow('05-0174', '76918[...]', 'Завершение'),
                      _damageRow('05-0002', '76919[...]', 'Завершение'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _damageRow(String car, String order, String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: adminBorder))),
      child: Row(
        children: [
          SizedBox(
            width: 400,
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: adminBorder,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: adminBorder),
                  ),
                  child: Icon(Icons.image, size: 30, color: adminTextGray),
                ),
              ],
            ),
          ),
          SizedBox(width: 150, child: Text(car, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(order, style: const TextStyle(fontSize: 11, color: adminInfo))),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.grid_view, size: 14, color: adminTextGray),
                const SizedBox(width: 4),
                Text(type, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledInput(String label, double width) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: adminTextGray)),
        const SizedBox(width: 4),
        SizedBox(
          width: width,
          height: 28,
          child: TextField(
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
            ),
            style: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: Icon(Icons.close, size: 14, color: Colors.grey[500])),
      ],
    );
  }

  Widget _chipBtn(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}
