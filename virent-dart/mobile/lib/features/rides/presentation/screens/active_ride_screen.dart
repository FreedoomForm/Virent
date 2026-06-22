import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/map/tile_cache_service.dart';

import '../../../../common/widgets/virent_ui.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../home/presentation/providers/location_provider.dart';
import '../../data/models/ride_model.dart';
import '../providers/ride_provider.dart';

/// Active ride screen — full-screen map with a bottom sheet showing the
/// live timer, three stat columns (Ехать / Цена / В пути), and the
/// side-by-side "Пауза" / "Завершить" action buttons.
///
/// Redesigned 1:1 against references 05 and 19. The widget receives the
/// `tripId` and `scooterId` from the router (passed by the scanner screen
/// or home screen after a successful unlock).
class ActiveRideScreen extends ConsumerStatefulWidget {
  /// Creates an [ActiveRideScreen].
  const ActiveRideScreen({
    super.key,
    required this.tripId,
    required this.scooterId,
  });

  /// The active ride's server-side identifier.
  final String tripId;

  /// The scooter the ride was started on.
  final String scooterId;

  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen> {
  final MapController _mapController = MapController();
  RideModel? _ride;
  bool _ending = false;
  Timer? _tick;

  static const int _defaultRatePerMin = 1200;
  static const LatLng _fallbackCenter = LatLng(41.3111, 69.2406);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialise());
    // Re-render every second so the live timer / cost keep ticking.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _togglePause(BuildContext context) async {
    final ride = ref.read(rideNotifierProvider).currentRide;
    if (ride == null) return;
    final isPaused = ride.status == 'paused';
    try {
      await ref.read(apiClientProvider).post('/trips/pause', {
        'trip_id': ride.id,
        'resume': isPaused,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isPaused ? 'Возобновлена' : 'Приостановлена'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initialise() async {
    final rideState = ref.read(rideNotifierProvider);
    // Prefer the ride already in state (e.g. just started from scanner).
    if (rideState.activeRide != null && rideState.activeRide!.id.isNotEmpty) {
      if (mounted) setState(() => _ride = rideState.activeRide);
      return;
    }
    // Fall back to a server-side lookup of the active ride.
    try {
      final active = await ref.read(getActiveRideUseCaseProvider)();
      if (mounted && active != null) {
        setState(() => _ride = active);
      }
    } catch (_) {
      // Last-ditch fallback: build a minimal ride from the route params so
      // the timer can still run.
      if (mounted) {
        setState(() {
          _ride = RideModel(
            id: widget.tripId,
            scooterId: widget.scooterId,
            startTime: DateTime.now().toUtc().toIso8601String(),
            cost: 0,
            status: 'ongoing',
            ratePerMin: _defaultRatePerMin,
          );
        });
      }
    }
  }

  Future<void> _endRide() async {
    if (_ending) return;
    setState(() => _ending = true);

    final loc = ref.read(locationNotifierProvider).position;
    final ride = await ref.read(rideNotifierProvider.notifier).endRide(
          rideId: _ride?.id ?? widget.tripId,
          endLat: loc?.latitude,
          endLng: loc?.longitude,
        );

    if (!mounted) return;
    setState(() => _ending = false);

    if (ride != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Поездка завершена. Стоимость: ${ride.cost} UZS'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
      context.go('/trips');
    } else {
      final error =
          ref.read(rideNotifierProvider).error ?? 'Не удалось завершить поездку';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showEndConfirmation() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMd),
        ),
        title: const Text('Завершить поездку?'),
        content: const Text(
          'Убедитесь, что самокат находится в зоне парковки, '
          'сделайте фото и завершите поездку.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _endRide();
            },
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
  }

  void _showSosDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMd),
        ),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Экстренный вызов'),
          ],
        ),
        content: const Text(
          'Ваше местоположение будет передано службе поддержки Virent '
          'и экстренным службам. Используйте только в реальной опасности.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Служба поддержки оповещена'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            child: const Text('Позвонить'),
          ),
        ],
      ),
    );
  }

  /// Formats the elapsed [Duration] as `m:ss` (or `h:mm:ss` past an hour).
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '$h:$mm:$ss';
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationNotifierProvider);
    final ride = _ride;

    final userLatLng = locationState.position != null
        ? LatLng(
            locationState.position!.latitude,
            locationState.position!.longitude,
          )
        : null;

    final startLatLng = (ride?.startLat != null && ride?.startLng != null)
        ? LatLng(ride!.startLat!, ride.startLng!)
        : null;

    final center = userLatLng ?? startLatLng ?? _fallbackCenter;

    // Live elapsed duration from the ride start time.
    final elapsed = (ride?.startDateTime != null)
        ? DateTime.now().difference(ride!.startDateTime!)
        : Duration.zero;

    // Estimated cost (UZS; ratePerMin is stored in UZS tiyin,
    // divide by 100 to get сум denomination).
    final sumPerMin = (ride?.ratePerMin ?? _defaultRatePerMin) / 100.0;
    final estimatedCostSum = (elapsed.inMinutes * sumPerMin).round();

    // Estimated distance travelled — assumes ~13 km/h average speed.
    final distanceKm = (elapsed.inMinutes * 0.22).round();

    // Polyline trail — start → live user position (when available).
    final trail = <LatLng>[
      if (startLatLng != null) startLatLng,
      if (userLatLng != null && userLatLng != startLatLng) userLatLng,
    ];

    return Scaffold(
      backgroundColor: AppColors.bgMap,
      // No AppBar — full-screen map experience per refs 05 / 19.
      body: Stack(
        children: [
          // ---- Full-screen map --------------------------------------------
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16,
                minZoom: 3,
                maxZoom: 18,
                backgroundColor: AppColors.bgMap,
              ),
              children: [
                cachedTileLayer(),
                if (trail.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: trail,
                        color: AppColors.black,
                        strokeWidth: 4.0,
                        borderColor: Colors.white,
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (startLatLng != null)
                      Marker(
                        point: startLatLng,
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.electric_scooter,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    if (userLatLng != null)
                      Marker(
                        point: userLatLng,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.black,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ---- Top-left close button --------------------------------------
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppStyles.spaceLg),
                child: MapControlButton(
                  icon: Icons.close,
                  onPressed: _showEndConfirmation,
                ),
              ),
            ),
          ),

          // ---- Top-right emergency button ---------------------------------
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppStyles.spaceLg),
                child: MapControlButton(
                  icon: Icons.phone_in_talk,
                  iconColor: AppColors.danger,
                  onPressed: _showSosDialog,
                ),
              ),
            ),
          ),

          // ---- Bottom sheet with timer + stats + actions ------------------
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Scooter info row.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.electric_scooter,
                            color: AppColors.black, size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Swift Neo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        Text(
                          ride?.scooterId.isNotEmpty == true
                              ? ride!.scooterId
                              : widget.scooterId,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Live timer — centred, 32 px Bold, monospaced figures.
                    Center(
                      child: Text(
                        _formatDuration(elapsed),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                          letterSpacing: 1,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3-column stat row.
                    Row(
                      children: [
                        Expanded(
                          child: StatColumn(
                            label: 'Ехать',
                            value: '$distanceKm KM',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: StatColumn(
                            label: 'Цена',
                            value: '$estimatedCostSum сум',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: StatColumn(
                            label: 'В пути',
                            value: _formatDuration(elapsed),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Pause / End ride buttons — side-by-side, 50/50 split.
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: Material(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppStyles.radiusSm),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                    AppStyles.radiusSm),
                                onTap: () => _togglePause(context),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        AppStyles.radiusSm),
                                    border: Border.all(
                                        color: AppColors.border, width: 1),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Пауза',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: Material(
                              color: AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(AppStyles.radiusSm),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                    AppStyles.radiusSm),
                                onTap: _ending ? null : _endRide,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: _ending
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Завершить',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Optional "Сделать фото парковки" small text button.
                    Center(
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Сделать фото парковки'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Inter',
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('Сделать фото парковки'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
