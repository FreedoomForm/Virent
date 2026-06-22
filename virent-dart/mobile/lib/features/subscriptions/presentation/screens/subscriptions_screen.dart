// subscriptions_screen.dart — Swift Pass subscription screen.
//
// Redesigned to match the Swift Scooter reference mockup:
//   - DARK background `#1C1C1E` with white text
//   - Back button circle (white/10 bg, white icon)
//   - Lime Swift Pass icon (64×64, lime bg, black Star icon)
//   - Title "Swift Pass" (32 px Bold)
//   - Description "Бесплатный старт и пауза, сниженные тарифы на поездки."
//   - 3 benefit rows (lime check circle + label)
//   - Plan toggle (1 месяц / 3 месяца) — lime selected bg
//   - Price "199 сум 249 сум" (line-through old price)
//   - PrimaryButton "Оформить подписку"
//   - Footer "Далее 199 сум / мес. Отменить можно в любой момент."

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../../common/widgets/virent_ui.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  bool _isMonthly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Top bar with back button ----------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.chevron_left,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Swift Pass icon ---------------------------------
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        LucideIcons.star,
                        color: AppColors.black,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ---- Title + description -----------------------------
                    const Text(
                      'Swift Pass',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Inter',
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Бесплатный старт и пауза,\nсниженные тарифы на поездки.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.60),
                        fontFamily: 'Inter',
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ---- Benefits list ----------------------------------
                    _BenefitRow(text: 'Бесплатный старт 0сум'),
                    const SizedBox(height: 20),
                    _BenefitRow(text: 'Минута паузы бесплатно'),
                    const SizedBox(height: 20),
                    _BenefitRow(text: 'Кэшбек 5% баллами'),

                    const Spacer(),

                    // ---- Plan toggle -------------------------------------
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          // Animated selected bg
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: _isMonthly
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              width: MediaQuery.of(context).size.width / 2 - 28,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _isMonthly = true),
                                  child: Container(
                                    height: 44,
                                    color: Colors.transparent,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '1 месяц',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _isMonthly
                                            ? AppColors.black
                                            : Colors.white,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _isMonthly = false),
                                  child: Container(
                                    height: 44,
                                    color: Colors.transparent,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '3 месяца',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: !_isMonthly
                                            ? AppColors.black
                                            : Colors.white,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ---- Price -------------------------------------------
                    Center(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _isMonthly ? '199 сум' : '499 сум',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: _isMonthly ? '249 сум' : '699 сум',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.40),
                                fontFamily: 'Inter',
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ---- CTA ---------------------------------------------
                    PrimaryButton(
                      label: 'Оформить подписку',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Подписка будет доступна позже'),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ---- Footer note -------------------------------------
                    Center(
                      child: Text(
                        _isMonthly
                            ? 'Далее 199 сум / мес. Отменить можно в любой момент.'
                            : 'Далее 499 сум / 3 мес. Отменить можно в любой момент.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.40),
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.20),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.check,
            color: AppColors.primary,
            size: 14,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}
