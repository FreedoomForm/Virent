// welcome_screen.dart — Swift onboarding screen.
//
// Redesigned to match the Swift Scooter reference mockup:
//   - White background
//   - Centered title "Аренда самоката" (24 px Bold)
//   - Subtitle "Арендуйте самокат за 30 секунд" (15 px gray)
//   - Hero: black rounded square with lime Zap icon
//   - Primary CTA "Поехали" (lime, 56 px, 20 px radius)
//   - Skip text button below

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/services/storage_service.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../../common/widgets/virent_ui.dart';

/// First-run onboarding screen.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _getStarted() async {
    final storage = StorageService();
    await storage.setBool(StorageKeys.isFirstRun, false);
    await storage.setBool(StorageKeys.onboardingComplete, true);
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ---- Hero icon -------------------------------------------------
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 32,
                          spreadRadius: 4,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.zap,
                      color: AppColors.primary,
                      size: 56,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // ---- Title + subtitle -----------------------------------------
              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    const Text(
                      'Аренда самоката',
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
                    Text(
                      'Арендуйте самокат за 30 секунд.\nБез залога и бумажных документов.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // ---- Primary CTA ----------------------------------------------
              PrimaryButton(
                label: 'Поехали',
                onPressed: _getStarted,
              ),

              const SizedBox(height: 16),

              // ---- Skip ----------------------------------------------------
              TextButton(
                onPressed: _getStarted,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  minimumSize: const Size.fromHeight(40),
                ),
                child: const Text(
                  'Пропустить',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontFamily: 'Inter',
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
