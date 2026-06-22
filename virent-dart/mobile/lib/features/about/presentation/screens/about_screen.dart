// about_screen.dart — Swift about app screen.
//
// Redesigned to match the Swift Scooter reference mockup:
//   - White background
//   - Back button circle + centered title "О приложении"
//   - Centered: Swift brand icon (32×32 black square w/ lime Zap)
//   - "Swift" title (24 px Bold)
//   - "Версия 1.93.0 (2)" (14 px gray)
//   - Card with 3 legal links: Политика конфиденциальности,
//     Пользовательское соглашение, Оферта

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/constants/app_constants.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../../common/widgets/virent_ui.dart';

class AboutAppScreen extends ConsumerWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Top bar ------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  BackButtonCircle(onPressed: () => context.pop()),
                  const Expanded(
                    child: Text(
                      'О приложении',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ---- Brand icon + title -------------------------------
                    const ScooterBrandIcon(size: 48),
                    const SizedBox(height: 24),
                    const Text(
                      'Swift',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Версия ${AppConstants.appVersion} (${AppConstants.buildNumber})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ---- Legal links card ---------------------------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _LegalLink(
                            label: 'Политика конфиденциальности',
                            isFirst: true,
                            onTap: () => _showInfo(context,
                                'Политика конфиденциальности',
                                'Здесь будет текст политики конфиденциальности.'),
                          ),
                          _LegalLink(
                            label: 'Пользовательское соглашение',
                            onTap: () => _showInfo(context,
                                'Пользовательское соглашение',
                                'Здесь будет текст пользовательского соглашения.'),
                          ),
                          _LegalLink(
                            label: 'Оферта',
                            isLast: true,
                            onTap: () => _showInfo(
                                context, 'Оферта', 'Здесь будет текст оферты.'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Понятно',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.borderStrong, width: 1),
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const Icon(
              LucideIcons.chevron_left,
              color: AppColors.textMuted,
              size: 20,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
