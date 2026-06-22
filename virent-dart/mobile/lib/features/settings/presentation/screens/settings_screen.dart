import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/constants/app_constants.dart';
import '../../../../core/configs/services/api_client.dart';
import '../../../../core/configs/services/storage_service.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../../core/services/ngrok_tunnel_service.dart';
import '../../../theme/presentation/providers/theme_provider.dart';

/// Настройки — экран в стиле референса: список с иконками и шевронами,
/// волосы-разделители, белый фон, секции Сервер / Тема / Язык /
/// Уведомления / Аккаунт / О приложении.
///
/// Бизнес-логика, провайдеры и состояние сохранены без изменений — переписан
/// только UI (build-метод и приватные виджеты-секции).
class SettingsScreen extends ConsumerStatefulWidget {
  /// Создаёт [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

/// Поддерживаемые языки интерфейса.
class _LanguageOption {
  final String code;
  final String label;

  const _LanguageOption(this.code, this.label);
}

const List<_LanguageOption> _languages = [
  _LanguageOption('ru', 'Русский'),
  _LanguageOption('en', 'English'),
  _LanguageOption('uz', 'O‘zbekcha'),
];

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late String _serverUrl;
  late String _languageCode;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  bool _loadingSessions = false;
  List<_SessionRow> _sessions = const [];

  /// `true` when the current session belongs to an admin / super_admin.
  /// Gate-keeps the "Сервер" URL editor and the "SMS-шлюз" row — these
  /// features must not be reachable by ordinary riders.
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _serverUrl = 'http://localhost:8443'; // Fixed
    _languageCode = 'ru'; // Default to Russian per redesign brief
    _loadAdminFlag();
  }

  /// Reads the admin flag from SharedPreferences. An admin session is
  /// identified by either the `admin_token` key or a `user_json` whose
  /// `role` field is `admin` / `super_admin`.
  Future<void> _loadAdminFlag() async {
    final storage = StorageService();
    await storage.init();
    final adminToken = await storage.getString('admin_token');
    if (adminToken != null && adminToken.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isAdmin = true);
      return;
    }
    final userJson = await storage.getJson(StorageKeys.userJson);
    if (userJson == null) {
      if (!mounted) return;
      setState(() => _isAdmin = false);
      return;
    }
    final role = (userJson['role'] ?? '').toString().toLowerCase();
    if (!mounted) return;
    setState(() => _isAdmin = role == 'admin' || role == 'super_admin');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider).isDark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Настройки',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppStyles.spaceLg, AppStyles.spaceSm, AppStyles.spaceLg, 32),
        children: [
          // ---- Сервер (admin-only) ------------------------------------
          // Editing the embedded server URL is an admin-only operation.
          // Ordinary riders see a read-only display of the current URL
          // without the tap-to-edit affordance.
          if (_isAdmin) ...[
            const _SectionLabel('Сервер'),
            _SettingsCard(
              children: [
                _SettingsRow(
                  icon: Icons.dns_outlined,
                  label: 'Локальный сервер',
                  trailing: Text(
                    _serverUrl,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: _editServerUrl,
                ),
                // ngrok tunnel — STABLE permanent URL
                Consumer(builder: (context, ref, _) {
                  final status = ref.watch(tunnelStatusProvider);
                  final url = ref.watch(tunnelUrlProvider);
                  if (status == TunnelStatus.running || url != null) {
                    return _SettingsRow(
                      icon: Icons.cloud_done_outlined,
                      label: 'Публичный URL (ngrok)',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              NgrokTunnelService.url,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Введите этот URL в Android → Настройки → Сервер'),
                            action: SnackBarAction(
                              label: 'OK',
                              onPressed: () {},
                            ),
                          ),
                        );
                      },
                      showDivider: false,
                    );
                  } else if (status == TunnelStatus.extracting) {
                    return _SettingsRow(
                      icon: Icons.download_outlined,
                      label: 'Извлечение ngrok...',
                      trailing: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      showDivider: false,
                    );
                  } else if (status == TunnelStatus.starting) {
                    return _SettingsRow(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Запуск ngrok...',
                      trailing: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      showDivider: false,
                    );
                  } else if (status == TunnelStatus.notFound) {
                    return _SettingsRow(
                      icon: Icons.cloud_off_outlined,
                      label: 'ngrok недоступен',
                      trailing: const Text(
                        'Не встроен',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      showDivider: false,
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
            const SizedBox(height: AppStyles.spaceXl),
          ],

          const _SectionLabel('Тема'),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                label: 'Тёмная тема',
                trailing: _AdaptiveSwitch(
                  value: isDark,
                  onChanged: (_) =>
                      ref.read(themeProvider.notifier).toggleTheme(),
                ),
                onTap: () =>
                    ref.read(themeProvider.notifier).toggleTheme(),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceXl),

          const _SectionLabel('Язык'),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.language_outlined,
                label: 'Язык',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _languageLabel(_languageCode),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textMuted, size: 20),
                  ],
                ),
                onTap: _showLanguagePicker,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceXl),

          const _SectionLabel('Уведомления'),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.notifications_outlined,
                label: 'Push-уведомления',
                trailing: _AdaptiveSwitch(
                  value: _pushNotifications,
                  onChanged: (v) =>
                      setState(() => _pushNotifications = v),
                ),
              ),
              _SettingsRow(
                icon: Icons.email_outlined,
                label: 'Email-уведомления',
                trailing: _AdaptiveSwitch(
                  value: _emailNotifications,
                  onChanged: (v) =>
                      setState(() => _emailNotifications = v),
                ),
              ),
              _SettingsRow(
                icon: Icons.sms_outlined,
                label: 'SMS-уведомления',
                trailing: _AdaptiveSwitch(
                  value: _smsNotifications,
                  onChanged: (v) =>
                      setState(() => _smsNotifications = v),
                ),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceXl),

          const _SectionLabel('Аккаунт'),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.lock_outline,
                label: 'Сменить пароль',
                onTap: () => context.push('/profile'),
              ),
              _SettingsRow(
                icon: Icons.devices_outlined,
                label: 'Активные сессии',
                trailing: _loadingSessions
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _showSessions,
                showDivider: !_isAdmin,
              ),
              // SMS-шлюз — admin-only. Hidden from ordinary riders so they
              // cannot reach the SIM-slot assignment screen.
              if (_isAdmin)
                _SettingsRow(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'SMS-шлюз (админ)',
                  iconColor: AppColors.primary,
                  showDivider: false,
                  onTap: () => context.push('/admin/sms-gateway'),
                ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceXl),

          const _SectionLabel('О приложении'),
          _SettingsCard(
            children: [
              const _SettingsRow(
                icon: Icons.info_outline,
                label: 'Версия',
                trailing: Text(
                  '${AppConstants.appVersion} (${AppConstants.buildNumber})',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              _SettingsRow(
                icon: Icons.description_outlined,
                label: 'Условия использования',
                onTap: () => context.push('/profile'),
              ),
              _SettingsRow(
                icon: Icons.privacy_tip_outlined,
                label: 'Политика конфиденциальности',
                showDivider: false,
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceXl),

          // Sign-out button — red outline.
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusSm),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: AppColors.danger, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Выйти',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppStyles.spaceLg),
          const Text(
            'Virent v${AppConstants.appVersion} — Flutter',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  // ---- Helpers --------------------------------------------------------------

  String _languageLabel(String code) {
    return _languages
        .firstWhere(
          (l) => l.code == code,
          orElse: () => const _LanguageOption('ru', 'Русский'),
        )
        .label;
  }

  Future<void> _editServerUrl() async {
    final controller = TextEditingController(text: _serverUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('URL сервера'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'http://192.168.1.100:8443',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null) return;
    final trimmed = result.trim();
    if (trimmed.isEmpty || trimmed == _serverUrl) return;

    setState(() => _serverUrl = trimmed);
    await StorageService().setString(StorageKeys.serverUrl, trimmed);
    try {
      await ApiClient().setBaseUrl(trimmed);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('URL сервера обновлён: $trimmed'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _showLanguagePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppStyles.radiusMd)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppStyles.spaceMd),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppStyles.spaceLg),
              const Text(
                'Язык',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: AppStyles.spaceSm),
              ..._languages.map((l) {
                final selected = l.code == _languageCode;
                return ListTile(
                  title: Text(
                    l.label,
                    style: TextStyle(
                      fontSize: 16,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, l.code),
                );
              }),
              const SizedBox(height: AppStyles.spaceSm),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      await _changeLanguage(selected);
    }
  }

  Future<void> _changeLanguage(String code) async {
    if (code == _languageCode) return;
    setState(() => _languageCode = code);
    await StorageService().setString(StorageKeys.language, code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Язык изменён на ${_languageLabel(code)}'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _showSessions() async {
    setState(() => _loadingSessions = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final sessions = <_SessionRow>[
      const _SessionRow(
        device: 'Это устройство',
        location: 'Ташкент, UZ',
        lastActive: 'Активно сейчас',
        isCurrent: true,
      ),
      const _SessionRow(
        device: 'Chrome на macOS',
        location: 'Ташкент, UZ',
        lastActive: '2 часа назад',
        isCurrent: false,
      ),
    ];
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loadingSessions = false;
    });

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppStyles.radiusMd)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppStyles.spaceMd),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppStyles.spaceLg),
              const Text(
                'Активные сессии',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: AppStyles.spaceSm),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _sessions.length,
                  itemBuilder: (_, index) {
                    final s = _sessions[index];
                    return ListTile(
                      leading: Icon(
                        s.isCurrent
                            ? Icons.phone_iphone
                            : Icons.laptop_mac,
                        color: s.isCurrent
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      title: Text(s.device),
                      subtitle: Text('${s.location} • ${s.lastActive}'),
                      trailing: s.isCurrent
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Текущая',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            )
                          : TextButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('Завершить'),
                            ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppStyles.spaceMd),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await StorageService().clearAuth();
    if (mounted) context.go('/welcome');
  }
}

// ---- Helpers -----------------------------------------------------------------

class _SessionRow {
  final String device;
  final String location;
  final String lastActive;
  final bool isCurrent;

  const _SessionRow({
    required this.device,
    required this.location,
    required this.lastActive,
    required this.isCurrent,
  });
}

/// Заголовок секции настроек — мелкий серый текст.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppStyles.spaceSm),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

/// Карточка секции — белый фон, скругление 8px, серая граница.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

/// Строка настроек — 56px высота, иконка слева, лейбл по центру,
/// trailing-виджет или шеврон справа, волосный разделитель снизу.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.iconColor = AppColors.textSecondary,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceLg),
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5),
                ),
              )
            : null,
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: AppStyles.spaceLg),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 24),
          ],
        ),
      ),
    );
  }
}

/// Switch-обёртка — нужна чтобы клик по строке и по свитчу не конфликтовали.
class _AdaptiveSwitch extends StatelessWidget {
  const _AdaptiveSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
