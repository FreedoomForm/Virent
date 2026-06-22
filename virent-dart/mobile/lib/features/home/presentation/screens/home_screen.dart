import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../common/widgets/virent_ui.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../rides/presentation/providers/ride_provider.dart';
import '../../data/models/scooter_model.dart';
import '../providers/location_provider.dart';
import '../providers/scooter_provider.dart';
import '../widgets/location_permission_handler.dart';
import '../widgets/search_modal.dart';

/// Home screen — the rider's landing page.
///
/// Redesigned 1:1 against references 10/11/12/13/14/15/27: a full-screen
/// `FlutterMap` with a top overlay (menu button + "Куда едем?" pill search
/// bar + filter), a right-side vertical cluster of map controls (zoom +/-,
/// recenter, scooter-list toggle), and a context-dependent bottom area that
/// swaps between:
///   * the default 3-tab bottom nav (Список / Карта / Профиль),
///   * a docked scooter-list sheet (refs 12, 17),
///   * a docked selected-scooter sheet with tariff picker + "Поехали" CTA
///     (refs 14, 15, 27).
///
/// All Riverpod providers (`scooterNotifierProvider`, `locationNotifierProvider`,
/// `rideNotifierProvider`), the `_startRide` flow, and the `/scanner`,
/// `/profile`, `/active-ride` routes are preserved.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  static const LatLng _fallbackCenter = LatLng(41.3111, 69.2406);

  /// Whether the scooter-list sheet (ref 12) is docked over the map.
  bool _showScooterList = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scooterState = ref.watch(scooterNotifierProvider);
    final locationState = ref.watch(locationNotifierProvider);

    final userPosition = locationState.position;
    final center = userPosition != null
        ? LatLng(userPosition.latitude, userPosition.longitude)
        : _fallbackCenter;

    final hasSelected = scooterState.selected != null;
    // Bottom-area mode:
    //   * selected scooter → selected-scooter sheet (refs 14, 15, 27)
    //   * list toggle      → scooter-list sheet (ref 12)
    //   * default          → 3-tab bottom nav (ref 10)
    final bool showBottomNav = !hasSelected && !_showScooterList;

    return Scaffold(
      backgroundColor: AppColors.bgMap,
      // No AppBar — map goes edge-to-edge.
      body: Stack(
        children: [
          // ---- Full-screen map ----------------------------------------------
          Positioned.fill(
            child: LocationPermissionHandler(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15.0,
                  minZoom: 3,
                  maxZoom: 18,
                  backgroundColor: AppColors.bgMap,
                  onMapReady: () {
                    if (userPosition != null) {
                      _mapController.move(center, 16.0);
                    }
                  },
                  onTap: (_, __) => ref
                      .read(scooterNotifierProvider.notifier)
                      .clearSelection(),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.virent.mobile',
                  ),
                  MarkerLayer(
                    markers: _buildMarkers(scooterState, userPosition),
                  ),
                ],
              ),
            ),
          ),

          // ---- Top overlay: menu + "Куда едем?" pill + filter ---------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppStyles.spaceLg,
                  AppStyles.spaceLg,
                  AppStyles.spaceLg,
                  0,
                ),
                child: Row(
                  children: [
                    MapControlButton(
                      icon: Icons.menu,
                      size: 40,
                      onPressed: () => context.go('/settings'),
                    ),
                    const SizedBox(width: AppStyles.spaceSm),
                    Expanded(
                      child: PillSearchBar(
                        hint: 'Куда едем?',
                        onTap: () => _showRoutePanel(context),
                      ),
                    ),
                    const SizedBox(width: AppStyles.spaceSm),
                    MapControlButton(
                      icon: Icons.tune,
                      size: 40,
                      onPressed: () => _showSearch(context),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---- Right-side map controls cluster (zoom +/-, location, list) ---
          Positioned(
            right: AppStyles.spaceLg,
            bottom: showBottomNav ? 80 : 24,
            child: Column(
              children: [
                MapControlButton(
                  icon: Icons.add,
                  onPressed: _zoomIn,
                ),
                const SizedBox(height: AppStyles.spaceSm),
                MapControlButton(
                  icon: Icons.remove,
                  onPressed: _zoomOut,
                ),
                const SizedBox(height: AppStyles.spaceSm),
                MapControlButton(
                  icon: Icons.my_location,
                  iconColor: AppColors.primary,
                  onPressed: () => _recenter(userPosition, center),
                ),
                const SizedBox(height: AppStyles.spaceSm),
                MapControlButton(
                  icon: Icons.list,
                  iconColor: _showScooterList
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  onPressed: () {
                    ref.read(scooterNotifierProvider.notifier).clearSelection();
                    setState(() => _showScooterList = !_showScooterList);
                  },
                ),
              ],
            ),
          ),

          // ---- QR-scanner FAB (ref 10 — dark green #2E7D32, above bottom nav)
          if (showBottomNav)
            Positioned(
              right: AppStyles.spaceLg,
              bottom: 72,
              child: MapFab(
                icon: Icons.qr_code_scanner,
                size: 60,
                backgroundColor: AppColors.primaryDark,
                iconColor: Colors.white,
                onPressed: () => context.go('/scanner'),
              ),
            ),

          // ---- Bottom area: context-dependent --------------------------------
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: hasSelected
                  ? _SelectedScooterSheet(
                      scooter: scooterState.selected!,
                      onClose: () => ref
                          .read(scooterNotifierProvider.notifier)
                          .clearSelection(),
                      onLetsGo: () => _startRide(scooterState.selected!),
                    )
                  : _showScooterList
                      ? _ScooterListSheet(
                          scooters: scooterState.scooters
                              .where((s) => s.isAvailable)
                              .toList(),
                          onClose: () =>
                              setState(() => _showScooterList = false),
                          onSelect: (s) {
                            ref
                                .read(scooterNotifierProvider.notifier)
                                .selectScooter(s);
                            setState(() => _showScooterList = false);
                          },
                        )
                      : _buildBottomNav(context),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Map markers ----------------------------------------------------------

  List<Marker> _buildMarkers(ScooterState state, Position? userPosition) {
    final markers = <Marker>[];

    // Rider location marker — black dot per brief.
    if (userPosition != null) {
      markers.add(Marker(
        point: LatLng(userPosition.latitude, userPosition.longitude),
        width: 24,
        height: 24,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ));
    }

    // Scooter markers — all green #34C759 per brief.
    for (final scooter in state.scooters) {
      final isSelected = state.selected?.id == scooter.id;
      markers.add(Marker(
        point: scooter.location,
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => ref
              .read(scooterNotifierProvider.notifier)
              .selectScooter(scooter),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.scooterMarker,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: isSelected ? 4 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: isSelected ? 10 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.electric_scooter,
                color: Colors.white, size: 22),
          ),
        ),
      ));
    }
    return markers;
  }

  // ---- Map control actions --------------------------------------------------

  void _zoomIn() {
    final zoom = (_mapController.camera.zoom + 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, zoom);
  }

  void _zoomOut() {
    final zoom = (_mapController.camera.zoom - 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, zoom);
  }

  void _recenter(Position? userPosition, LatLng center) {
    if (userPosition != null) {
      _mapController.move(center, 16.0);
    } else {
      ref.read(locationNotifierProvider.notifier).requestAndStart();
    }
  }

  // ---- Modals ---------------------------------------------------------------

  void _showSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SearchModal(),
    );
  }

  /// Opens the route-building panel (ref 13 — "Куда едем?" expanded).
  void _showRoutePanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RouteBuildingSheet(),
    );
  }

  // ---- Ride start -----------------------------------------------------------

  Future<void> _startRide(ScooterModel scooter) async {
    final messenger = ScaffoldMessenger.of(context);
    final ride = await ref.read(rideNotifierProvider.notifier).startRide(
          scooterId: scooter.id,
        );
    if (!mounted) return;
    if (ride != null) {
      context.go('/active-ride?tripId=${ride.id}&scooterId=${ride.scooterId}');
    } else {
      final error =
          ref.read(rideNotifierProvider).error ?? 'Failed to start ride';
      messenger.showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ---- Bottom navigation ----------------------------------------------------

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavTab(
            icon: Icons.list,
            label: 'Список',
            isActive: false,
            onTap: () => setState(() => _showScooterList = true),
          ),
          _NavTab(
            icon: Icons.map_outlined,
            label: 'Карта',
            isActive: true,
            onTap: () {
              setState(() => _showScooterList = false);
            },
          ),
          _NavTab(
            icon: Icons.person_outline,
            label: 'Профиль',
            isActive: false,
            onTap: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Inline widgets — bottom navigation, selected-scooter sheet, scooter-list
// sheet, route-building panel.
// ============================================================================

/// Single icon-only tab in the 3-tab bottom nav (ref 10).
class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusSm),
      child: SizedBox(
        width: 72,
        child: Icon(
          icon,
          size: 24,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
          semanticLabel: label,
        ),
      ),
    );
  }
}

/// Selected-scooter sheet — refs 14, 15, 27.
///
/// 16 px top radius, white bg, scooter header (name + ID + battery), tariff
/// picker (Поминутный / Фиксированный), payment row, "Поехали" CTA, close X.
class _SelectedScooterSheet extends StatefulWidget {
  const _SelectedScooterSheet({
    required this.scooter,
    required this.onClose,
    required this.onLetsGo,
  });

  final ScooterModel scooter;
  final VoidCallback onClose;
  final VoidCallback onLetsGo;

  @override
  State<_SelectedScooterSheet> createState() => _SelectedScooterSheetState();
}

class _SelectedScooterSheetState extends State<_SelectedScooterSheet> {
  /// `true` → "Поминутный" (per-minute), `false` → "Фиксированный" (fixed).
  bool _perMinute = true;

  @override
  Widget build(BuildContext context) {
    final scooter = widget.scooter;
    final batteryColor = scooter.battery > 50
        ? AppColors.batteryHigh
        : scooter.battery > 20
            ? AppColors.batteryMid
            : AppColors.batteryLow;
    final rangeKm = ((scooter.battery / 100) * 40).round();
    final hours = (scooter.battery / 18).floor();
    final minutes = ((scooter.battery / 18) * 60).round() % 60;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppStyles.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Header row: scooter name + ID + close X ---------------------
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scooter.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scooter.id,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.battery_std,
                      color: batteryColor, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    '${scooter.battery}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: batteryColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              // Close X (top-right of sheet).
              Positioned(
                right: -8,
                top: -8,
                child: IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textSecondary, size: 22),
                  onPressed: widget.onClose,
                  tooltip: 'Закрыть',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceSm),
          // ---- Battery line — "100% до 40 км на 5 ч 32 мин" ----------------
          Text(
            '${scooter.battery}% до $rangeKm км на $hours ч $minutes мин',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.batteryHigh,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: AppStyles.spaceLg),
          // ---- Tariff selector — two side-by-side cards --------------------
          Row(
            children: [
              Expanded(
                child: _TariffCard(
                  label: 'Поминутный',
                  sublabel: '${scooter.ratePerMin} сум/мин',
                  selected: _perMinute,
                  onTap: () => setState(() => _perMinute = true),
                ),
              ),
              const SizedBox(width: AppStyles.spaceSm),
              Expanded(
                child: _TariffCard(
                  label: 'Фиксированный',
                  sublabel: '249 сум/час',
                  selected: !_perMinute,
                  onTap: () => setState(() => _perMinute = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceLg),
          // ---- Payment method row -------------------------------------------
          _PaymentRow(onTap: () => context.push('/payments')),
          const SizedBox(height: AppStyles.spaceLg),
          // ---- "Поехали" CTA ------------------------------------------------
          CtaButton(
            label: 'Поехали',
            icon: Icons.lock_open,
            height: 56,
            onPressed: scooter.isAvailable && scooter.hasSufficientBattery
                ? widget.onLetsGo
                : null,
          ),
        ],
      ),
    );
  }
}

/// Side-by-side tariff card. Selected → pure black bg + white text.
/// Unselected → light gray bg + black text.
class _TariffCard extends StatelessWidget {
  const _TariffCard({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(AppStyles.spaceLg),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Payment method row — "T-Банк • 1589" + yellow chip + chevron.
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spaceLg, vertical: AppStyles.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        ),
        child: Row(
          children: [
            // Yellow T-Bank chip.
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.brandYellow,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Т',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: AppStyles.spaceMd),
            const Expanded(
              child: Text(
                'T-Банк • 1589',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Scooter-list sheet — ref 12.
///
/// Bottom sheet with a header ("Самокаты рядом") and 3 scooter cards. Each
/// card: white bg, 8 px radius, 16 px padding, hairline border, color-coded
/// battery.
class _ScooterListSheet extends StatelessWidget {
  const _ScooterListSheet({
    required this.scooters,
    required this.onClose,
    required this.onSelect,
  });

  final List<ScooterModel> scooters;
  final VoidCallback onClose;
  final ValueChanged<ScooterModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
          AppStyles.spaceXl, AppStyles.spaceMd, AppStyles.spaceXl, AppStyles.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Самокаты рядом',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    color: AppColors.textSecondary, size: 22),
                onPressed: onClose,
                tooltip: 'Закрыть',
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceSm),
          Flexible(
            child: scooters.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Нет доступных самокатов поблизости',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: scooters.length > 3 ? 3 : scooters.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppStyles.spaceSm),
                    itemBuilder: (context, index) {
                      final s = scooters[index];
                      return _ScooterListCard(
                        scooter: s,
                        onTap: () => onSelect(s),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// A single scooter row in the scooter-list sheet (ref 12).
class _ScooterListCard extends StatelessWidget {
  const _ScooterListCard({required this.scooter, required this.onTap});

  final ScooterModel scooter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final batteryColor = scooter.battery > 50
        ? AppColors.batteryHigh
        : scooter.battery > 20
            ? AppColors.batteryMid
            : AppColors.batteryLow;
    final distanceText = scooter.distance == null
        ? '—'
        : scooter.distance! >= 1000
            ? '${(scooter.distance! / 1000).toStringAsFixed(1)} км'
            : '${scooter.distance} м';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppStyles.spaceLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(AppStyles.radiusSm),
              ),
              child: const Icon(Icons.electric_scooter,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppStyles.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scooter.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${scooter.id}  •  $distanceText',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.battery_std, color: batteryColor, size: 18),
            const SizedBox(width: 4),
            Text(
              '${scooter.battery}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: batteryColor,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Route-building panel — ref 13.
///
/// Expands the "Куда едем?" pill into a bottom sheet with "Откуда" + "Куда"
/// inputs and a "Недавно" section listing recent destinations.
class _RouteBuildingSheet extends StatelessWidget {
  const _RouteBuildingSheet();

  static const List<_RecentAddress> _recent = [
    _RecentAddress(
      name: 'Камчатская 45',
      address: 'Пермь, Камчатская улица',
    ),
    _RecentAddress(
      name: 'Пермская 43, подъезд 1',
      address: 'Пермь, Пермская улица',
    ),
    _RecentAddress(
      name: 'ТЦ Самарканд',
      address: 'Пермь, ул. Революции 12',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppStyles.spaceXl, AppStyles.spaceMd, AppStyles.spaceXl, AppStyles.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Header: title + close ----------------------------------------
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Куда едем?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    color: AppColors.textSecondary, size: 22),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Закрыть',
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceSm),
          // ---- "Откуда" + "Куда" inputs -------------------------------------
          const _RouteInputField(
            icon: Icons.radio_button_checked,
            iconColor: AppColors.primary,
            hint: 'Откуда',
          ),
          const SizedBox(height: AppStyles.spaceSm),
          const _RouteInputField(
            icon: Icons.location_on,
            iconColor: AppColors.destinationMarker,
            hint: 'Куда',
          ),
          const SizedBox(height: AppStyles.spaceLg),
          // ---- "Недавно" section --------------------------------------------
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Недавно',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: AppStyles.spaceSm),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recent.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final r = _recent[index];
                return _RecentAddressTile(recent: r);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "Откуда" / "Куда" input row in the route-building panel.
class _RouteInputField extends StatelessWidget {
  const _RouteInputField({
    required this.icon,
    required this.iconColor,
    required this.hint,
    this.controller,
    this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppStyles.spaceMd),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                hintStyle: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single recent-address row in the route-building panel.
class _RecentAddressTile extends StatelessWidget {
  const _RecentAddressTile({required this.recent});

  final _RecentAddress recent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).maybePop(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppStyles.spaceMd, horizontal: AppStyles.spaceXs),
        child: Row(
          children: [
            const Icon(Icons.history, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: AppStyles.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recent.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recent.address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Simple value holder for the route-building "Недавно" list.
class _RecentAddress {
  const _RecentAddress({required this.name, required this.address});

  final String name;
  final String address;
}
