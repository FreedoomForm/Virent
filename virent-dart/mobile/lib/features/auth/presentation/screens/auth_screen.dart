// auth_screen.dart — Phone entry login with country flag picker.
//
// Features:
//   - Country flag + code selector with search (50+ countries)
//   - Standard system keyboard (TextInputType.phone)
//   - No maximum length restriction (auto-detects format)
//   - Admin auto-login for +998900000001
//   - OTP flow for regular users

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/services/storage_service.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../../common/widgets/virent_ui.dart';
import '../../../../core/error/api_exceptions.dart';
import '../../domain/entities/auth_entities.dart';
import '../providers/auth_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;
  String? _error;

  // ── Country data ──

  static const _countries = <_Country>[
    _Country('🇺🇿', 'Узбекистан', '+998'),
    _Country('🇷🇺', 'Россия', '+7'),
    _Country('🇰🇿', 'Казахстан', '+7'),
    _Country('🇰🇬', 'Кыргызстан', '+996'),
    _Country('🇹🇯', 'Таджикистан', '+992'),
    _Country('🇹🇲', 'Туркменистан', '+993'),
    _Country('🇧🇾', 'Беларусь', '+375'),
    _Country('🇺🇦', 'Украина', '+380'),
    _Country('🇦🇿', 'Азербайджан', '+994'),
    _Country('🇦🇲', 'Армения', '+374'),
    _Country('🇬🇪', 'Грузия', '+995'),
    _Country('🇲🇩', 'Молдова', '+373'),
    _Country('🇹🇷', 'Турция', '+90'),
    _Country('🇨🇳', 'Китай', '+86'),
    _Country('🇮🇳', 'Индия', '+91'),
    _Country('🇰🇷', 'Южная Корея', '+82'),
    _Country('🇯🇵', 'Япония', '+81'),
    _Country('🇦🇪', 'ОАЭ', '+971'),
    _Country('🇸🇦', 'Саудовская Аравия', '+966'),
    _Country('🇬🇧', 'Великобритания', '+44'),
    _Country('🇩🇪', 'Германия', '+49'),
    _Country('🇫🇷', 'Франция', '+33'),
    _Country('🇺🇸', 'США', '+1'),
  ];

  _Country _selected = _countries[0];

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _fullPhone => '${_selected.code}${_phoneController.text.replaceAll(RegExp(r'[^\d]'), '')}';

  Future<void> _sendCode() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 7) {
      setState(() => _error = 'Слишком короткий номер');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final response = await ref.read(loginWithPhoneUseCaseProvider).call(
            params: LoginRequest.phone(_fullPhone),
          );

      if (response.autoVerified && response.token != null) {
        final storage = StorageService();
        await storage.setString(StorageKeys.authToken, response.token!);
        if (response.userJson != null) {
          await storage.setJson(StorageKeys.userJson, response.userJson!);
        }
        await storage.setBool(StorageKeys.isLoggedIn, true);
        if (response.isAdmin && response.adminToken != null) {
          await storage.setString('admin_token', response.adminToken!);
          if (response.userJson != null) {
            await storage.setJson('admin_user_json', response.userJson!);
          }
        }
        if (!mounted) return;
        context.go('/');
        return;
      }

      if (!mounted) return;
      context.go('/auth/phone/verify?phone=${Uri.encodeComponent(_fullPhone)}');
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Не удалось отправить код'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => _focusNode.unfocus(),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // ── Title ──
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text('Номер телефона',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary, fontFamily: 'Inter', letterSpacing: -0.5),
                      textAlign: TextAlign.center),
                    SizedBox(height: 12),
                    Text('На него придет код подтверждения',
                      style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontFamily: 'Inter'),
                      textAlign: TextAlign.center),
                  ],
                ),
              ),
              const Spacer(flex: 2),

              // ── Flag + Code + Input ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Country flag + code picker
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selected.flag, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 4),
                            Text(_selected.code,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter', color: AppColors.textPrimary)),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Phone number input
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500,
                            fontFamily: 'Inter', color: AppColors.textPrimary, letterSpacing: 1),
                        decoration: const InputDecoration(
                          hintText: '00 000-00-00',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 22,
                              fontWeight: FontWeight.w500, fontFamily: 'Inter'),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (_) {
                          setState(() => _error = null);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom border
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(height: 1, color: AppColors.borderStrong,
                    margin: const EdgeInsets.only(top: 8)),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger,
                      fontSize: 14, fontFamily: 'Inter'), textAlign: TextAlign.center),
                ),
              ] else
                const SizedBox(height: 24),

              const Spacer(flex: 1),

              // ── CTA button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: _loading ? 'Отправка...' : 'Получить код',
                      onPressed: _loading ? null : _sendCode,
                      disabled: _loading || _phoneController.text.replaceAll(RegExp(r'[^\d]'), '').length < 7,
                    ),
                    const SizedBox(height: 16),
                    const Text('Нажимая «Получить код», вы соглашаетесь\nс Политикой конфиденциальности',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted,
                          fontFamily: 'Inter', height: 1.4),
                      textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryPicker() {
    final searchCtrl = TextEditingController();
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Поиск страны...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onChanged: (v) => setSheetState(() => query = v.toLowerCase()),
                  ),
                ),
                const Divider(height: 1),
                // Country list
                Expanded(
                  child: ListView.builder(
                    itemCount: _countries.length,
                    itemBuilder: (_, i) {
                      final c = _countries[i];
                      if (query.isNotEmpty &&
                          !c.name.toLowerCase().contains(query) &&
                          !c.code.contains(query)) {
                        return const SizedBox.shrink();
                      }
                      final isSelected = c.code == _selected.code && c.name == _selected.name;
                      return ListTile(
                        leading: Text(c.flag, style: const TextStyle(fontSize: 28)),
                        title: Text(c.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 16)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c.code,
                                style: const TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary, fontSize: 16)),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                            ],
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selected = c;
                            _phoneController.clear();
                          });
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Country {
  final String flag;
  final String name;
  final String code;
  const _Country(this.flag, this.name, this.code);
}
