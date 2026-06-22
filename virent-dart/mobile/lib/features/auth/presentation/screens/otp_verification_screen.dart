// otp_verification_screen.dart — Swift OTP confirmation screen.
//
// Redesigned to match the Swift Scooter reference mockup:
//   - White background
//   - Back button circle (top-left)
//   - Title "Код подтверждения" (28 px Bold)
//   - Subtitle "Отправили на +7 922 243-67-56" (15 px gray)
//   - 4-cell code input — each cell 60×72, 16 px radius, lime `#BEF264` border
//     on the active cell, gray border otherwise
//   - Resend code timer / link below
//   - Same numeric keypad as AuthScreen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../../core/error/api_exceptions.dart';
import '../../../../common/widgets/virent_ui.dart';
import '../../domain/entities/auth_entities.dart';
import '../providers/auth_providers.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.verificationId,
  });

  final String phoneNumber;
  final String? verificationId;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const _length = 6;

  String _code = '';
  bool _loading = false;
  bool _error = false;
  int _attemptsLeft = 3;
  String? _errorMessage;

  Timer? _resendTimer;
  int _remaining = 15;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _remaining = 15);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining == 0) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
    });
  }

  String get _formattedPhone {
    final p = widget.phoneNumber.startsWith('+7')
        ? widget.phoneNumber.substring(2)
        : widget.phoneNumber;
    if (p.length < 10) return widget.phoneNumber;
    return '${p.substring(0, 3)} ${p.substring(3, 6)} ${p.substring(6, 8)}-${p.substring(8, 10)}';
  }

  void _onDigit(String d) {
    if (_code.length >= _length) return;
    setState(() {
      _code += d;
      _error = false;
      _errorMessage = null;
    });
    if (_code.length == _length) {
      _verify();
    }
  }

  void _onBackspace() {
    if (_code.isEmpty) return;
    setState(() {
      _code = _code.substring(0, _code.length - 1);
      _error = false;
      _errorMessage = null;
    });
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorMessage = null;
    });
    try {
      await ref.read(verifyOtpUseCaseProvider).call(
            params: VerifyOtpParams(
              phoneNumber: widget.phoneNumber,
              otp: _code,
              verificationId: widget.verificationId ?? '',
            ),
          );
      if (!mounted) return;
      context.go('/');
    } on ApiException catch (e) {
      setState(() {
        _error = true;
        _errorMessage = e.message;
        _attemptsLeft--;
        _loading = false;
        _code = '';
      });
    } catch (_) {
      setState(() {
        _error = true;
        _errorMessage = 'Неверный код';
        _attemptsLeft--;
        _loading = false;
        _code = '';
      });
    }
  }

  Future<void> _resend() async {
    if (_remaining > 0) return;
    setState(() => _loading = true);
    try {
      await ref.read(loginWithPhoneUseCaseProvider).call(
            params: LoginRequest.phone(widget.phoneNumber),
          );
      _startResendTimer();
      setState(() {
        _loading = false;
        _code = '';
        _error = false;
        _errorMessage = null;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Top bar with back button ----------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: BackButtonCircle(
                  onPressed: () => context.go('/auth'),
                ),
              ),
            ),

            const Spacer(flex: 1),

            // ---- Title + subtitle ------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'Код подтверждения',
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
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Отправили на ',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        TextSpan(
                          text: '+7 $_formattedPhone',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // ---- 4-cell code input -----------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_length, (i) {
                  final isActive = i == _code.length;
                  final filled = i < _code.length;
                  return Container(
                    width: 48,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _error
                            ? AppColors.danger
                            : isActive
                                ? AppColors.primaryBorder
                                : AppColors.borderStrong,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      filled ? _code[i] : '',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // ---- Error / countdown feedback --------------------------
            if (_error && _errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Осталось $_attemptsLeft ${_attemptsLeft == 1 ? 'попытка' : 'попытки'}',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: _remaining == 0 ? _resend : null,
                child: Text(
                  _remaining > 0
                      ? 'Запросить код повторно через 0:${_remaining.toString().padLeft(2, '0')}'
                      : 'Отправить код повторно',
                  style: TextStyle(
                    color: _remaining > 0
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontSize: 15,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],

            const Spacer(flex: 1),

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
                Icons.backspace_outlined,
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
