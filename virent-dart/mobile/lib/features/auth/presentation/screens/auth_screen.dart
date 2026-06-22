// auth_screen.dart — Swift phone-entry login screen.
//
// Redesigned to match the Swift Scooter reference mockup:
//   - White background
//   - Title "Номер телефона" (28 px Bold, centered)
//   - Subtitle "На него придет код подтверждения" (15 px gray)
//   - Russian flag chip + "+7" prefix + phone input with bottom border
//   - PrimaryButton "Получить код" (disabled until 10 digits entered)
//   - Privacy policy hint
//   - Custom numeric keypad on gray `#D1D5DB` background:
//       1 2 3
//       4 5 6
//       7 8 9
//         0 ⌫
//     Each key: white bg, 16 px radius, 46 px height
//     Backspace key: gray `#ABB0B8` bg

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/services/storage_service.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../../core/error/api_exceptions.dart';
import '../../../../common/widgets/virent_ui.dart';
import '../../domain/entities/auth_entities.dart';
import '../providers/auth_providers.dart';

/// Phone-entry login screen with custom numeric keypad.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  String _phone = '';
  bool _loading = false;
  String? _error;

  static const _maxLength = 10;

  /// Country code selection — list of supported countries.
  static const _countries = <_CountryCode>[
    _CountryCode(code: '+7', flag: '🇷🇺', name: 'Россия', maxLength: 10),
    _CountryCode(code: '+998', flag: '🇺🇿', name: 'Узбекистан', maxLength: 9),
    _CountryCode(code: '+7', flag: '🇰🇿', name: 'Казахстан', maxLength: 10),
    _CountryCode(code: '+375', flag: '🇧🇾', name: 'Беларусь', maxLength: 9),
    _CountryCode(code: '+992', flag: '🇹🇯', name: 'Таджикистан', maxLength: 9),
    _CountryCode(code: '+996', flag: '🇰🇬', name: 'Кыргызстан', maxLength: 9),
    _CountryCode(code: '+993', flag: '🇹🇲', name: 'Туркменистан', maxLength: 8),
  ];

  _CountryCode _selectedCountry = _countries[0];

  Future<void> _sendCode() async {
    if (_phone.length < _selectedCountry.maxLength) {
      setState(() => _error = 'Введите номер полностью');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fullPhone = '${_selectedCountry.code}$phone';
      final response = await ref.read(loginWithPhoneUseCaseProvider).call(
            params: LoginRequest.phone(fullPhone),
          );

      // ---- Admin auto-login (skip OTP) ----
      // The embedded server auto-verifies admin phones and returns the
      // full auth payload directly in the send-code response. Persist
      // the session and navigate to the admin panel.
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
        // Router redirect will send admins to /admin/home
        context.go('/');
        return;
      }

      // ---- Regular OTP flow ----
      if (!mounted) return;
      context.go('/auth/phone/verify?phone=${Uri.encodeComponent(fullPhone)}');
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось отправить код. Попробуйте ещё раз.';
        _loading = false;
      });
    }
  }

  void _onDigit(String d) {
    if (_phone.length >= _selectedCountry.maxLength) return;
    setState(() {
      _phone += d;
      _error = null;
    });
  }

  void _onBackspace() {
    if (_phone.isEmpty) return;
    setState(() {
      _phone = _phone.substring(0, _phone.length - 1);
      _error = null;
    });
  }

  /// Formats "9222436756" as "922 243-67-56" for display.
  String get _formatted {
    final p = _phone;
    if (p.length <= 3) return p;
    if (p.length <= 6) return '${p.substring(0, 3)} ${p.substring(3)}';
    if (p.length <= 8) {
      return '${p.substring(0, 3)} ${p.substring(3, 6)}-${p.substring(6)}';
    }
    return '${p.substring(0, 3)} ${p.substring(3, 6)}-${p.substring(6, 8)}-${p.substring(8)}';
  }

  String get phone => _phone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // ---- Title + subtitle ------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'Номер телефона',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'На него придет код подтверждения',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // ---- Phone display ---------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Country code selector — tappable, opens bottom sheet
                  GestureDetector(
                    onTap: _showCountryPicker,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(_selectedCountry.flag,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Icon(LucideIcons.chevron_down,
                              size: 12, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Selected country code prefix
                  Text(
                    _selectedCountry.code,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Phone digits
                  Expanded(
                    child: Text(
                      _formatted.isEmpty
                          ? '000 000-00-00'
                          : _formatted,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                        color: _phone.isEmpty
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom border under phone row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 1,
                color: AppColors.borderStrong,
                margin: const EdgeInsets.only(top: 12),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
            ],

            const Spacer(flex: 1),

            // ---- Primary CTA + privacy note --------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  PrimaryButton(
                    label: _loading ? 'Отправка...' : 'Получить код',
                    onPressed: _loading ? null : _sendCode,
                    disabled: _phone.length < _selectedCountry.maxLength,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Нажимая «Получить код», вы соглашаетесь\nс Политикой конфиденциальности',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontFamily: 'Inter',
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---- Custom numeric keypad -------------------------------
            _NumericKeypad(
              onDigit: _onDigit,
              onBackspace: _onBackspace,
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a bottom sheet to pick the country code.
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Выберите страну',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const Divider(height: 1),
            ..._countries.map((c) {
              final isSelected = c.code == _selectedCountry.code &&
                  c.name == _selectedCountry.name;
              return ListTile(
                leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                title: Text(c.name,
                    style: const TextStyle(fontFamily: 'Inter')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.code,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary)),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check, color: AppColors.primary, size: 20),
                    ],
                  ],
                ),
                onTap: () {
                  setState(() {
                    _selectedCountry = c;
                    _phone = ''; // Clear phone when country changes
                  });
                  Navigator.of(ctx).pop();
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Country code definition for the phone-input picker.
class _CountryCode {
  const _CountryCode({
    required this.code,
    required this.flag,
    required this.name,
    required this.maxLength,
  });

  /// Dial code (e.g. '+7', '+998').
  final String code;

  /// Flag emoji.
  final String flag;

  /// Country name in Russian.
  final String name;

  /// Max digits after the dial code.
  final int maxLength;
}
class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _letters = <String>[
    '', 'ABC', 'DEF', 'GHI', 'JKL', 'MNO',
    'PQRS', 'TUV', 'WXYZ', '', '', '',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgKeypad,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
      child: Column(
        children: [
          Row(children: [
            _key('1', 0), _key('2', 1), _key('3', 2),
          ]),
          Row(children: [
            _key('4', 3), _key('5', 4), _key('6', 5),
          ]),
          Row(children: [
            _key('7', 6), _key('8', 7), _key('9', 8),
          ]),
          Row(children: [
            const Spacer(),
            _key('0', 10),
            _backspace(),
          ]),
        ],
      ),
    );
  }

  Widget _key(String digit, int lettersIdx) {
    return Expanded(
      child: Container(
        height: 46,
        margin: const EdgeInsets.all(4),
        child: Material(
          color: AppColors.bgKeypadKey,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onDigit(digit),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  digit,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                if (_letters[lettersIdx].isNotEmpty) ...[
                  const SizedBox(height: 0),
                  Text(
                    _letters[lettersIdx],
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.5,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _backspace() {
    return Expanded(
      child: Container(
        height: 46,
        margin: const EdgeInsets.all(4),
        child: Material(
          color: AppColors.bgKeypadBackspace,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onBackspace,
            child: const Center(
              child: Icon(
                LucideIcons.delete,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
