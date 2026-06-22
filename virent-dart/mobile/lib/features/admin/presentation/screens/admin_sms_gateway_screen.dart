// admin_sms_gateway_screen.dart
//
// Admin SMS Gateway — the admin's Android phone acts as an SMS sender.
// When a regular user registers, the server asks the admin's phone
// (via WebSocket or polling) to send an OTP SMS from the selected SIM.
//
// Architecture:
//   User registers -> Server generates OTP -> Server pushes OTP to admin phone
//   -> Admin phone sends SMS via SmsManager (selected SIM) -> User receives OTP
//
// This works because:
// 1. The admin phone runs the Virent app in "admin mode".
// 2. The app has SEND_SMS permission.
// 3. On dual-SIM phones, the admin can choose which SIM to use.
// 4. The server uses the admin phone as an SMS gateway (no paid SMS API needed).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/configs/services/storage_service.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../../core/error/api_exceptions.dart';

/// Platform-channel bridge for Android SMS APIs.
///
/// On a real device this would call `MethodChannel('virent/sms')` to invoke
/// Android's `SmsManager` from the Kotlin host activity. In the sandbox it
/// returns deterministic mock data so the UI can be exercised end-to-end.
///
/// **All mutating operations are admin-only.** Each method re-checks the
/// admin flag in SharedPreferences before touching the platform channel —
/// this is the second line of defense behind the route guard in
/// `app_router.dart` (which already blocks `/admin/sms-gateway` for non-
/// admin sessions).
class SmsService {
  /// Lists the SIM cards present in the device.
  ///
  /// Each entry is `{slotIndex, carrierName, phoneNumber, iccId}`.
  ///
  /// Read-only — does not require admin. (Riders never call this anyway
  /// because the SMS-gateway screen is admin-gated at the router level.)
  Future<List<Map<String, dynamic>>> getSimCards() async {
    try {
      final res = await const MethodChannel('virent/sms')
          .invokeListMethod<Map>('getSimInfo');
      if (res != null) {
        return res.cast<Map>().map((m) => m.cast<String, dynamic>()).toList();
      }
    } catch (e) {
      debugPrint('[SMS] MethodChannel error: $e');
    }
    // Fallback mock data
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'slotIndex': 0,
        'carrierName': 'Beeline',
        'phoneNumber': '+998901234567',
        'iccId': '8901234567890123456',
      },
      <String, dynamic>{
        'slotIndex': 1,
        'carrierName': 'Ucell',
        'phoneNumber': '+998931234567',
        'iccId': '8901234567890123457',
      },
    ];
  }

  /// Returns `true` when the active session belongs to an admin.
  Future<bool> _isAdminSession() async {
    final storage = StorageService();
    await storage.init();
    final adminToken = await storage.getString('admin_token');
    if (adminToken != null && adminToken.isNotEmpty) return true;
    final userJson = await storage.getJson(StorageKeys.userJson);
    if (userJson == null) return false;
    final role = (userJson['role'] ?? '').toString().toLowerCase();
    return role == 'admin' || role == 'super_admin';
  }

  /// Sends [message] to [phone] from the SIM in [simSlot].
  ///
  /// Returns `true` on success. **Admin-only** — throws
  /// [UnauthorizedException] when the current session is not an admin.
  Future<bool> sendSms(String phone, String message, int simSlot) async {
    if (!await _isAdminSession()) {
      throw UnauthorizedException(
        'Только администратор может отправлять SMS через шлюз',
      );
    }
    try {
      await const MethodChannel('virent/sms').invokeMethod('sendSms', {
        'phone': phone,
        'message': message,
        'simSlot': simSlot,
      });
      debugPrint('[SMS GATEWAY] SIM $simSlot -> $phone: $message');
      return true;
    } catch (e) {
      debugPrint('[SMS GATEWAY] Failed: $e');
      return false;
    }
  }

// ============ Admin SMS Gateway providers ==================================

/// Singleton [SmsService] used by the gateway screen.
final smsServiceProvider = Provider<SmsService>((ref) => SmsService());

  }
/// Async list of SIM cards detected on the device.
final simCardsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(smsServiceProvider).getSimCards();
});

/// Currently selected SIM slot (persisted across sessions).
final selectedSimSlotProvider =
    StateNotifierProvider<SelectedSimSlotNotifier, int>((ref) {
  return SelectedSimSlotNotifier();
});

/// Notifier that persists the selected SIM slot to SharedPreferences.
///
/// The `set()` method is **admin-only** — it throws [UnauthorizedException]
/// when the current session is not an admin. This is the second line of
/// defense behind the route guard: even if a rider somehow reaches the
/// notifier (e.g. via a hot-reload state injection), the slot change is
/// rejected before being persisted.
class SelectedSimSlotNotifier extends StateNotifier<int> {
  SelectedSimSlotNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('sim_slot') ?? 0;
  }

  /// Updates the selected slot and persists it.
  ///
  /// **Admin-only.** Throws [UnauthorizedException] for non-admin sessions.
  Future<void> set(int slot) async {
    if (!await _isAdminSession()) {
      throw UnauthorizedException(
        'Только администратор может назначать SIM-карту для отправки SMS',
      );
    }
    state = slot;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sim_slot', slot);
  }

  /// Returns `true` when the active session belongs to an admin.
  /// Mirrors the same check performed by `app_router.dart`.
  Future<bool> _isAdminSession() async {
    final storage = StorageService();
    await storage.init();
    final adminToken = await storage.getString('admin_token');
    if (adminToken != null && adminToken.isNotEmpty) return true;
    final userJson = await storage.getJson(StorageKeys.userJson);
    if (userJson == null) return false;
    final role = (userJson['role'] ?? '').toString().toLowerCase();
    return role == 'admin' || role == 'super_admin';
  }
}

/// Whether the gateway is in admin mode (active).
final adminModeProvider = StateNotifierProvider<AdminModeNotifier, bool>((ref) {
  return AdminModeNotifier();
});

/// Notifier that persists the admin-mode flag.
class AdminModeNotifier extends StateNotifier<bool> {
  AdminModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('admin_mode') ?? false;
  }

  /// Toggles admin mode and persists the new value.
  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_mode', state);
  }
}

/// Chronological SMS log kept in memory (most recent last).
final smsLogProvider =
    StateNotifierProvider<SmsLogNotifier, List<SmsLogEntry>>((ref) {
  return SmsLogNotifier();
});

/// Notifier managing the SMS log.
class SmsLogNotifier extends StateNotifier<List<SmsLogEntry>> {
  SmsLogNotifier() : super(const <SmsLogEntry>[]);

  /// Appends a new entry.
  void add(SmsLogEntry entry) {
    state = [...state, entry];
  }

  /// Wipes the log.
  void clear() {
    state = const <SmsLogEntry>[];
  }
}

/// Immutable SMS log entry.
class SmsLogEntry {
  /// Creates an entry.
  const SmsLogEntry({
    required this.phone,
    required this.code,
    required this.time,
    required this.sim,
  });

  /// Recipient phone number (E.164).
  final String phone;

  /// OTP code sent.
  final String code;

  /// Timestamp of the send.
  final DateTime time;

  /// SIM slot used.
  final int sim;
}

// ============ Admin SMS Gateway Screen =====================================

/// Admin screen for SMS gateway configuration.
///
/// Shows available SIM cards (selectable), the SMS log (messages sent from
/// this phone), a test-SMS composer, and the admin-mode toggle in the app
/// bar. When admin mode is off the body is replaced with a placeholder.
class AdminSmsGatewayScreen extends ConsumerWidget {
  /// Creates the SMS gateway screen.
  const AdminSmsGatewayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(adminModeProvider);
    final selectedSlot = ref.watch(selectedSimSlotProvider);
    final simCardsAsync = ref.watch(simCardsProvider);
    final smsLog = ref.watch(smsLogProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin SMS Gateway'),
        actions: [
          Switch(
            value: isAdmin,
            onChanged: (v) => ref.read(adminModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: isAdmin
          ? ListView(
              padding: const EdgeInsets.all(AppStyles.spacing),
              children: [
                _StatusCard(theme: theme),
                const SizedBox(height: AppStyles.spacing),
                Text('Select SIM Card', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                simCardsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (sims) => Column(
                    children: sims
                        .map((sim) => _SimTile(
                              sim: sim,
                              selected: sim['slotIndex'] == selectedSlot,
                              onTap: () => ref
                                  .read(selectedSimSlotProvider.notifier)
                                  .set(sim['slotIndex'] as int),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppStyles.spacing),
                Row(
                  children: [
                    const Icon(Icons.sms, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('SMS Log (${smsLog.length} sent)',
                        style: theme.textTheme.labelLarge),
                    const Spacer(),
                    if (smsLog.isNotEmpty)
                      TextButton(
                        onPressed: ref.read(smsLogProvider.notifier).clear,
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (smsLog.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppStyles.cardDecorationCompact,
                    child: Center(
                      child: Text(
                        'No SMS sent yet',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...smsLog.reversed.take(20).map(
                        (log) => _LogTile(entry: log, theme: theme),
                      ),
                const SizedBox(height: AppStyles.spacing),
                OutlinedButton.icon(
                  onPressed: () => _sendTestSms(context, ref),
                  icon: const Icon(Icons.send),
                  label: const Text('Send Test SMS'),
                ),
              ],
            )
          : _DisabledState(theme: theme),
    );
  }

  /// Prompts for a phone number and dispatches a test SMS.
  Future<void> _sendTestSms(BuildContext context, WidgetRef ref) async {
    final phone = await _showPhoneDialog(context);
    if (phone == null || phone.isEmpty) return;

    final code =
        (100000 + DateTime.now().millisecond * 1000).toString().substring(0, 6);
    final simSlot = ref.read(selectedSimSlotProvider);
    final smsService = ref.read(smsServiceProvider);
    final success = await smsService.sendSms(phone, 'Your Virent code: $code', simSlot);

    if (success) {
      ref.read(smsLogProvider.notifier).add(SmsLogEntry(
            phone: phone,
            code: code,
            time: DateTime.now(),
            sim: simSlot,
          ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test SMS sent to $phone from SIM $simSlot')),
        );
      }
    }
  }

  /// Phone-number prompt dialog.
  Future<String?> _showPhoneDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Test SMS'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration:
              const InputDecoration(hintText: '+998901234567'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

/// "Gateway active" banner shown at the top of the screen.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecorationCompact,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gateway Active', style: theme.textTheme.labelLarge),
                Text(
                  'This phone is sending OTP SMS for new registrations',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable SIM card row.
class _SimTile extends StatelessWidget {
  const _SimTile({
    required this.sim,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic> sim;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.sim_card,
                size: 32,
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SIM ${sim['slotIndex']}',
                      style: theme.textTheme.labelLarge),
                  Text(
                    '${sim['carrierName']} · ${sim['phoneNumber']}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

/// Single SMS log row.
class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry, required this.theme});

  final SmsLogEntry entry;
  final ThemeData theme;

  String _format(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppStyles.cardDecorationCompact,
      child: Row(
        children: [
          const Icon(Icons.sms, size: 20, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('To: ${entry.phone}', style: theme.textTheme.labelLarge),
                Text(
                  'OTP: ${entry.code} · SIM ${entry.sim} · ${_format(entry.time)}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Sent',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder shown when admin mode is off.
class _DisabledState extends StatelessWidget {
  const _DisabledState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sms_failed, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Admin mode is off', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Toggle the switch above to enable this phone as an SMS gateway',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
