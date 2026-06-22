// update_banner.dart — overlay widget that shows update notifications.
//
// Renders a dismissible banner at the TOP of the screen when an update
// is available. Includes:
//   - Version number + "Доступно обновление" label
//   - "Обновить" button → triggers download
//   - Progress bar (0–100%) during download
//   - "Установка..." label when installer is launching
//   - Error message if something went wrong
//   - "Позже" dismiss button
//
// The banner auto-checks for updates 5 seconds after the app starts.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/configs/theme/app_colors.dart';
import '../../core/presentation/providers/update_provider.dart';
import '../../core/services/update_service.dart';

/// Wraps a child widget and overlays the update banner on top.
class UpdateBannerWrapper extends ConsumerStatefulWidget {
  const UpdateBannerWrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateBannerWrapper> createState() =>
      _UpdateBannerWrapperState();
}

class _UpdateBannerWrapperState extends ConsumerState<UpdateBannerWrapper> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    // Auto-check 5 seconds after launch (give the app time to boot).
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_checked) {
        _checked = true;
        ref.read(updateStateProvider.notifier).check();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateStateProvider);
    final progress = ref.watch(updateProgressProvider);
    final info = ref.watch(updateInfoProvider);

    // Only show the banner for these states.
    final showBanner = state == UpdateState.available ||
        state == UpdateState.downloading ||
        state == UpdateState.installing ||
        (state == UpdateState.error && ref.read(updateStateProvider.notifier).errorMessage != null);

    if (!showBanner) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Material(
              elevation: 8,
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Header row ----
                    Row(
                      children: [
                        Icon(LucideIcons.download, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _titleFor(state, info),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        if (state == UpdateState.available)
                          GestureDetector(
                            onTap: () =>
                                ref.read(updateStateProvider.notifier).dismiss(),
                            child: const Icon(LucideIcons.x,
                                color: Colors.white54, size: 18),
                          ),
                      ],
                    ),

                    // ---- Subtitle ----
                    if (state == UpdateState.available && info != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Версия ${info.version} • Нажмите «Обновить» для установки',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],

                    // ---- Progress bar ----
                    if (state == UpdateState.downloading) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                          backgroundColor: Colors.white24,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress > 0
                            ? 'Загрузка... ${(progress * 100).toInt()}%'
                            : 'Загрузка...',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],

                    // ---- Installing ----
                    if (state == UpdateState.installing) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Запуск установщика...',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ---- Error ----
                    if (state == UpdateState.error) ...[
                      const SizedBox(height: 4),
                      Text(
                        ref.read(updateStateProvider.notifier).errorMessage ??
                            'Ошибка обновления',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],

                    // ---- Action button ----
                    if (state == UpdateState.available) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => ref
                                  .read(updateStateProvider.notifier)
                                  .downloadAndInstall(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.black,
                                minimumSize: const Size.fromHeight(40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Обновить',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => ref
                                .read(updateStateProvider.notifier)
                                .dismiss(),
                            child: const Text(
                              'Позже',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ---- Retry (on error) ----
                    if (state == UpdateState.error) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref.read(updateStateProvider.notifier).dismiss();
                        },
                        child: const Text(
                          'Закрыть',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _titleFor(UpdateState state, UpdateInfo? info) {
    switch (state) {
      case UpdateState.available:
        return 'Доступно обновление${info != null ? ' ${info.version}' : ''}';
      case UpdateState.downloading:
        return 'Загрузка обновления...';
      case UpdateState.installing:
        return 'Установка обновления';
      case UpdateState.error:
        return 'Ошибка обновления';
      default:
        return '';
    }
  }
}
