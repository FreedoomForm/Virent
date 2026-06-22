import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../providers/location_provider.dart';

/// Wraps its [child] in a permission-aware scaffold.
///
/// On first build it kicks off [LocationNotifier.requestAndStart]. While
/// permission is being negotiated the child renders normally (the home
/// screen keeps working with the fallback Tashkent coordinates). When the
/// user denies permission an inline call-to-action is rendered instead.
///
/// Ported from BarqScoot's `LocationPermissionHandler` and re-skinned
/// with Virent tokens.
class LocationPermissionHandler extends ConsumerWidget {
  /// Creates a [LocationPermissionHandler].
  const LocationPermissionHandler({super.key, required this.child});

  /// The widget rendered when location access is available (or being
  /// negotiated).
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationNotifierProvider);

    // Kick off the permission request the first time we mount. The
    // notifier is idempotent so subsequent rebuilds are cheap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (location.status == LocationStatus.initial) {
        ref.read(locationNotifierProvider.notifier).requestAndStart();
      }
    });

    switch (location.status) {
      case LocationStatus.denied:
      case LocationStatus.deniedForever:
      case LocationStatus.serviceDisabled:
        return _PermissionDeniedView(
          status: location.status,
          message: location.error ??
              'Location access is required to show nearby scooters.',
        );
      case LocationStatus.error:
        return _PermissionDeniedView(
          status: location.status,
          message: location.error ?? 'Unable to determine your location.',
        );
      case LocationStatus.initial:
      case LocationStatus.loading:
      case LocationStatus.ready:
        return child;
    }
  }
}

/// Inline call-to-action shown when permission has been denied.
class _PermissionDeniedView extends ConsumerWidget {
  const _PermissionDeniedView({required this.status, required this.message});

  final LocationStatus status;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppStyles.spacing),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off,
                color: AppColors.warning, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Location access needed',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              if (status == LocationStatus.denied) {
                ref.read(locationNotifierProvider.notifier).requestAndStart();
              } else {
                ref.read(locationNotifierProvider.notifier).openAppSettings();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppStyles.borderRadius),
              ),
            ),
            icon: const Icon(Icons.location_searching),
            label: Text(
              status == LocationStatus.denied
                  ? 'Grant permission'
                  : 'Open settings',
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () =>
                ref.read(locationNotifierProvider.notifier).openLocationSettings(),
            icon: const Icon(Icons.settings),
            label: const Text('Open location settings'),
          ),
        ],
      ),
    );
  }
}
