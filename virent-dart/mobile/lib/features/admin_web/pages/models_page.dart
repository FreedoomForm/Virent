import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';
import '../widgets/admin_dialogs.dart';

class ModelsPage extends ConsumerWidget {
  const ModelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(scootersListProvider);
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Entries', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        SizedBox(width: 12),
                        Text('Показано 1 до 4 из 4 совпадений', style: TextStyle(fontSize: 11, color: adminTextGray)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить entry', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: adminPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      ),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
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
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 100, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 100, child: Text('Is public', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Image', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Brand', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Model', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Device type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _modelRow(context, '1', true, 'api/modelImage/', 'Ninebot', 'MAX', ''),
                      _modelRow(context, '3', true, 'api/modelImage/', 'Ninebot', 'MAX', ''),
                      _modelRow(context, '7', true, 'api/modelImage/', 'OKAI', 'ES400a', ''),
                      _modelRow(context, '10', true, 'api/modelImage/', 'OKAI', 'ES600', '2,156'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Container(
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 100, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 100, child: Text('Is public', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Image', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Brand', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Model', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Device type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _modelRow(BuildContext context, String id, bool isPublic, String image, String brand, String model, String deviceType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: adminBorder))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 100, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Icon(isPublic ? Icons.check_box_outlined : Icons.check_box_outline_blank, size: 16, color: adminSuccess),
              ],
            ),
          ),
          Expanded(child: Text(image, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(brand, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(model, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(deviceType, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.visibility, size: 12, color: adminInfo), SizedBox(width: 4), Text('Просмотр', style: TextStyle(fontSize: 10, color: adminInfo))])),
                const SizedBox(width: 12),
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.edit, size: 12, color: adminInfo), SizedBox(width: 4), Text('Редактировать', style: TextStyle(fontSize: 10, color: adminInfo))])),
                const SizedBox(width: 12),
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.delete, size: 12, color: adminDanger), SizedBox(width: 4), Text('Удалить', style: TextStyle(fontSize: 10, color: adminDanger))])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
