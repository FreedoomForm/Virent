// profile_screen.dart — Swift profile screen.
//
// Redesigned to match the Swift Scooter reference mockup:
//   - White background
//   - Back button circle + centered title "Профиль" (18 px Bold)
//   - Avatar (64×64, orange gradient bg) + name "Кетрин" (20 px Bold) +
//     phone "+7 922 243-67-56" (13 px gray) + bell icon (40×40 circle)
//   - 2 stat cards row:
//       "Школа вождения" (F9F9F9 bg, 24 px radius, Smartphone icon)
//       "34 КМ" (F9F9F9 bg, 24 px radius, History icon) → tappable to /trips
//   - Menu list (single 24 px-radius card, hairline dividers):
//       Способ оплаты (CreditCard icon, gray tile) → /payments
//       Подписка Swift Pass (Star icon, lime tile) → /subscriptions
//       Чат поддержки (LifeBuoy icon, gray tile) → /support
//       Промокоды и скидки (Percent icon, gray tile) → /promo-codes
//       О приложении (Info icon, gray tile) → /about
//   - Footer: "Юридическая информация" + "Версия 1.93.0 (2)" (11 px gray)

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/constants/app_constants.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../../common/widgets/virent_ui.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

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
                  BackButtonCircle(onPressed: () => context.go('/')),
                  const Expanded(
                    child: Text(
                      'Профиль',
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

            // ---- Body (scrollable) --------------------------------------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: userAsync.loading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _body(
                        context,
                        name: (userAsync.user?.firstName?.isNotEmpty == true
                            ? '${userAsync.user!.firstName} ${userAsync.user!.lastName ?? ''}'.trim()
                            : 'Гость'),
                        phone: userAsync.user?.phone ?? '+7 922 243-67-56',
                      ),
              ),
            ),

            // ---- Footer -------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Юридическая информация',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    'Версия ${AppConstants.appVersion} (${AppConstants.buildNumber})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, {required String name, required String phone}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Avatar + name + bell -----------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Avatar — 64×64 orange-gradient rounded square
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFED7AA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Yellow tint overlay (bottom 80%)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 51,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.brandOrange.withValues(alpha: 0.30),
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(20)),
                          ),
                        ),
                      ),
                      // Head circle
                      Positioned(
                        top: 19,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFED7AA),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      // Body
                      Positioned(
                        bottom: -4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFED7AA),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Bell icon (with red unread dot)
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.bell,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // ---- 2 stat cards -------------------------------------------
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: LucideIcons.smartphone,
                label: 'Школа вождения',
                value: null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/trips'),
                child: _StatCard(
                  icon: LucideIcons.history,
                  label: null,
                  value: '34 КМ',
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ---- Menu list (single card) --------------------------------
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              MenuRow(
                icon: LucideIcons.credit_card,
                label: 'Способ оплаты',
                onTap: () => context.push('/payments'),
                isFirst: true,
              ),
              MenuRow(
                icon: LucideIcons.star,
                label: 'Подписка Swift Pass',
                iconBackgroundColor: const Color(0xFFEFFBB3),
                iconColor: const Color(0xFF95B82D),
                onTap: () => context.push('/subscriptions'),
              ),
              MenuRow(
                icon: LucideIcons.life_buoy,
                label: 'Чат поддержки',
                onTap: () => context.push('/support'),
              ),
              MenuRow(
                icon: LucideIcons.percent,
                label: 'Промокоды и скидки',
                onTap: () => context.push('/promo-codes'),
              ),
              MenuRow(
                icon: LucideIcons.info,
                label: 'О приложении',
                onTap: () => context.push('/about'),
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stat card — 24 px radius, F9F9F9 bg, icon in white circle (top),
/// label or value (bottom).
class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, this.label, this.value});

  final IconData icon;
  final String? label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
            if (label != null)
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              )
            else if (value != null)
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
