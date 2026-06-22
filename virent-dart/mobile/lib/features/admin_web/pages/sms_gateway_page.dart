// sms_gateway_page.dart — Virent admin SMS gateway (web panel).
//
// Ported from the old admin_sms_gateway_screen.dart. The admin's Android
// phone acts as an SMS sender. The admin chooses which SIM card to use
// and tests SMS sending. Pending SMS queue is shown below.
//
// Wired to [smsLogsProvider] (GET /sms/pending) for the queue and
// [selectedSimSlotProvider] for SIM selection.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/configs/theme/app_colors.dart';
import '../../admin/presentation/screens/admin_sms_gateway_screen.dart'
    show smsServiceProvider, selectedSimSlotProvider;
import '../admin_web_providers.dart';

class SmsGatewayPage extends ConsumerStatefulWidget {
  const SmsGatewayPage({super.key});

  @override
  ConsumerState<SmsGatewayPage> createState() => _SmsGatewayPageState();
}

class _SmsGatewayPageState extends ConsumerState<SmsGatewayPage> {
  List<Map<String, dynamic>> _simCards = [];
  bool _loadingSims = true;
  final _testPhoneCtrl = TextEditingController();
  final _testMsgCtrl = TextEditingController(text: 'Test SMS from Virent');
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadSimCards();
  }

  @override
  void dispose() {
    _testPhoneCtrl.dispose();
    _testMsgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSimCards() async {
    try {
      final sims = await ref.read(smsServiceProvider).getSimCards();
      if (mounted) {
        setState(() {
          _simCards = sims;
          _loadingSims = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSims = false);
    }
  }

  Future<void> _sendTest() async {
    final phone = _testPhoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер телефона')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final simSlot = ref.read(selectedSimSlotProvider);
      await ref.read(smsServiceProvider).sendSms(phone, _testMsgCtrl.text, simSlot);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SMS отправлено на $phone (SIM $simSlot)')),
        );
        ref.invalidate(smsLogsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSlot = ref.watch(selectedSimSlotProvider);
    final smsAsync = ref.watch(smsLogsProvider);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SMS-шлюз',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter')),
          const SizedBox(height: 24),

          // SIM card selection
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SIM-карта для отправки',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 16),
                  if (_loadingSims)
                    const Center(child: CircularProgressIndicator())
                  else if (_simCards.isEmpty)
                    const Text('SIM-карты не обнаружены')
                  else
                    Row(
                      children: _simCards.map((sim) {
                        final slot = sim['slotIndex'] as int;
                        final isSelected = slot == selectedSlot;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(selectedSimSlotProvider.notifier)
                                  .set(slot),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(LucideIcons.card_sim,
                                            size: 20,
                                            color: isSelected
                                                ? AppColors.black
                                                : AppColors.textSecondary),
                                        const SizedBox(width: 8),
                                        Text('SIM ${slot + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Inter',
                                              color: isSelected
                                                  ? AppColors.black
                                                  : AppColors.textPrimary,
                                            )),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('${sim['carrierName'] ?? '-'}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Inter',
                                            color: isSelected
                                                ? AppColors.black
                                                : AppColors.textSecondary)),
                                    Text('${sim['phoneNumber'] ?? '-'}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                            color: isSelected
                                                ? AppColors.black
                                                : AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Test SMS
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Тестовая отправка',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _testPhoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Номер телефона',
                      hintText: '+998901234567',
                      prefixIcon: const Icon(LucideIcons.phone, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _testMsgCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Сообщение',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _sending ? null : _sendTest,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.send, size: 16),
                    label: Text(_sending ? 'Отправка...' : 'Отправить SMS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Queue
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.border),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Очередь SMS',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter')),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () => ref.invalidate(smsLogsProvider),
                          icon: const Icon(LucideIcons.refresh_cw, size: 16),
                          label: const Text('Обновить'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: smsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Ошибка: $e')),
                        data: (sms) {
                          if (sms.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.inbox, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 8),
                                  Text('Очередь пуста',
                                      style: TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                            );
                          }
                          return SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF9F9F9)),
                              columns: const [
                                DataColumn(label: Text('ID')),
                                DataColumn(label: Text('Получатель')),
                                DataColumn(label: Text('Сообщение')),
                                DataColumn(label: Text('SIM')),
                                DataColumn(label: Text('Статус')),
                                DataColumn(label: Text('Время')),
                              ],
                              rows: sms.map((s) {
                                return DataRow(cells: [
                                  DataCell(Text('${s['id'] ?? '-'}')),
                                  DataCell(Text('${s['to'] ?? s['phone'] ?? '-'}')),
                                  DataCell(Text('${s['body'] ?? s['message'] ?? '-'}')),
                                  DataCell(Text('${s['sim_slot'] ?? '-'}')),
                                  DataCell(_StatusChip(status: '${s['status'] ?? 'pending'}')),
                                  DataCell(Text('${s['at'] ?? s['created_at'] ?? '-'}')),
                                ]);
                              }).toList(),
                            ),
                          );
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
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    if (status == 'sent' || status == 'delivered') {
      color = AppColors.success;
    } else if (status == 'pending') {
      color = AppColors.warning;
    } else if (status == 'failed') {
      color = AppColors.danger;
    } else {
      color = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Inter')),
    );
  }
}
