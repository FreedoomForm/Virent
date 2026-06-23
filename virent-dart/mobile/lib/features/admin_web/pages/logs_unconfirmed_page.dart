import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class LogsUnconfirmedPage extends ConsumerWidget {
  const LogsUnconfirmedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(logsUnconfirmedProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
        return Container(
      color: const Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('Entries', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                    SizedBox(width: 12),
                    Text('Показано 1 до 20 из 15,114 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1700,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 80, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Phone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Sms code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Sms try count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Sms try count all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Sms try login', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Create time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Sms last attempt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 400, child: Text('Check key', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Api token', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Sms req', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _unconfirmedRow('314775', '998908702320', '610059', '0', '1', '0', '19 июн 2026, 05:26', '19 июн 2026, 05:26', '1061a39ae23cd383a5d3d0e5135517391949ddc9[...]'),
                          _unconfirmedRow('314766', '998930649249', '527592', '0', '1', '0', '19 июн 2026, 03:34', '19 июн 2026, 03:34', 'e665c59a29f9c13eff7df5dad191ae499706093a[...]'),
                          _unconfirmedRow('314751', '998971200200', '192542', '0', '1', '0', '19 июн 2026, 00:25', '19 июн 2026, 00:25', '9dfb684d89335505541b36e941ee05d6dedf980b[...]'),
                          _unconfirmedRow('314749', '998991035152', '321778', '0', '1', '0', '19 июн 2026, 00:23', '19 июн 2026, 00:23', '8c0270e39ccdf6d975ac0acf3cfcc983c2f7c1d[...]'),
                          _unconfirmedRow('314735', '998918307806', '881217', '0', '4', '0', '18 июн 2026, 23:48', '18 июн 2026, 23:49', '81f1a0f601ca9c7870ad7de4d074eaf2743fd2c1[...]'),
                          _unconfirmedRow('314699', '998996126989', '146884', '0', '2', '0', '18 июн 2026, 19:37', '18 июн 2026, 19:37', '4ae400ca3d2550078af32f412b03307c28f9fce5[...]'),
                          _unconfirmedRow('314674', '995599569332', '579940', '0', '3', '0', '18 июн 2026, 14:27', '18 июн 2026, 19:10', 'd9f6e85f86987878d430417d61749581888a865f[...]'),
                          _unconfirmedRow('314672', '998505903233', '535041', '0', '1', '0', '18 июн 2026, 14:12', '18 июн 2026, 14:12', '0108ac75bf5f5467c28572cb39770518a7ec9ce8[...]'),
                          _unconfirmedRow('314671', '79080504566', '571902', '0', '1', '0', '18 июн 2026, 14:08', '18 июн 2026, 14:08', '3badf3f3ee4c5737947dcbb519a47ddbc631caa5[...]'),
                          _unconfirmedRow('314644', '998974646164', '241526', '0', '1', '0', '18 июн 2026, 02:35', '18 июн 2026, 02:35', 'e4a700c6a77bab3b9a77c2f1f15d028110d86228[...]'),
                          _unconfirmedRow('314638', '998911060626', '224799', '0', '1', '0', '18 июн 2026, 02:03', '18 июн 2026, 02:03', 'b19db698ac0465b293b46d1ee471424c730210d0[...]'),
                          _unconfirmedRow('314619', '998504235551', '364449', '0', '1', '0', '18 июн 2026, 00:41', '18 июн 2026, 00:41', 'f48d36b053105bf6d9e556de9b1a65c2a2edd821[...]'),
                          _unconfirmedRow('314618', '998970000777', '412293', '0', '1', '0', '18 июн 2026, 00:31', '18 июн 2026, 00:31', '6dbc9939dce0662d1be59442491a0899af9a9c6a[...]'),
                          _unconfirmedRow('314602', '998994366421', '814935', '0', '1', '0', '17 июн 2026, 23:07', '17 июн 2026, 23:07', 'd1e93163524f0a3145711464b82184235a14cf04[...]'),
                          _unconfirmedRow('314598', '998992117601', '875380', '0', '1', '0', '17 июн 2026, 22:46', '17 июн 2026, 22:46', 'cac200fbe10cfe929e71cde98aa2aeb90b39cde6[...]'),
                          _unconfirmedRow('314576', '998945711816', '117345', '0', '1', '0', '17 июн 2026, 19:41', '17 июн 2026, 19:41', 'f9032cca2a1a68d86eaad013eddabc51316970e9[...]'),
                          _unconfirmedRow('314575', '79149377167', '592521', '0', '3', '0', '17 июн 2026, 19:23', '17 июн 2026, 21:40', '9eaa4523f3352fafab4d6cdd4c7806b623c705e8[...]'),
                          _unconfirmedRow('314572', '905387424523', '540166', '0', '2', '0', '17 июн 2026, 18:25', '17 июн 2026, 18:26', '9c55284b1f0f8d671f6ff5945b5db56d8cb16684[...]'),
                          _unconfirmedRow('314554', '998882540501', '484921', '0', '2', '0', '17 июн 2026, 11:20', '17 июн 2026, 11:21', 'f222b594b32aa67fc7ba4731843b199f4b6f92ed[...]'),
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
      },
    );
  }

  Widget _unconfirmedRow(String id, String phone, String smsCode, String count, String countAll, String tryLogin, String createTime, String lastAttempt, String checkKey) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 120, child: Text(phone, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(smsCode, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 120, child: Text(count, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 120, child: Text(countAll, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 120, child: Text(tryLogin, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(createTime, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(lastAttempt, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 400, child: Text(checkKey, style: const TextStyle(fontSize: 11))),
          const SizedBox(width: 100, child: Text('', style: TextStyle(fontSize: 11))), // Api token empty
          const SizedBox(width: 80, child: Text('', style: TextStyle(fontSize: 11))), // Sms req empty
          Expanded(
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
}
