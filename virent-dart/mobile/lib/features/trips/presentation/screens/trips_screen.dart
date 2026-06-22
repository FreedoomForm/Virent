import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../home/data/models/models.dart';
import '../../../home/data/repository/virent_repository.dart';

/// Ride history list — date-grouped sections (Сегодня, Вчера, 12 декабря, …)
/// with one tile per trip.
///
/// Redesigned 1:1 against reference 02. The screen pulls trips from the
/// existing [VirentRepository] and renders them as compact cards with the
/// time, cost, scooter info and duration on the left, and a hairline
/// divider between cards. Pull-to-refresh is enabled.
class TripsScreen extends StatefulWidget {
  /// Creates a [TripsScreen].
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final _repo = VirentRepository();
  List<Trip> _trips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trips = await _repo.getTrips();
      if (!mounted) return;
      // Newest first — the API may already return them sorted, but we
      // re-sort defensively so date-grouping lands in the right order.
      trips.sort((a, b) {
        final aTime = _parseTime(a.startTime);
        final bTime = _parseTime(b.startTime);
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      setState(() {
        _trips = trips;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить поездки';
      });
    }
  }

  static DateTime? _parseTime(String? iso) =>
      (iso == null || iso.isEmpty) ? null : DateTime.tryParse(iso)?.toLocal();

  /// Russian month names in genitive case ("12 декабря").
  static const _ruMonths = <String>[
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  /// Returns the human-readable date label used as a section header.
  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Вчера';
    return '${date.day} ${_ruMonths[date.month - 1]}';
  }

  /// Groups the trips by their date label, preserving the newest-first sort.
  List<({String label, List<Trip> trips})> _groupedByDate() {
    final groups = <String, List<Trip>>{};
    for (final t in _trips) {
      final dt = _parseTime(t.startTime) ?? DateTime.now();
      final key = _dateLabel(dt);
      groups.putIfAbsent(key, () => []).add(t);
    }
    // Preserve the original (newest-first) insertion order.
    return groups.entries.map((e) => (label: e.key, trips: e.value)).toList();
  }

  String _formatTime(String? iso) {
    final dt = _parseTime(iso);
    if (dt == null) return '—';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text(
          'История поездок',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: AppColors.border),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    // Error + empty both render a scrollable empty state so the pull-to-
    // refresh gesture still works.
    if (_error != null || _trips.isEmpty) {
      return ListView(
        // Still scrollable so RefreshIndicator works.
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.electric_scooter,
              size: 72, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Нет поездок',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      );
    }

    final groups = _groupedByDate();
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppStyles.spaceLg, AppStyles.spaceLg, AppStyles.spaceLg, 32),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, sectionIndex) {
        final group = groups[sectionIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Date header -------------------------------------------
            Padding(
              padding: const EdgeInsets.only(
                  top: AppStyles.spaceLg, bottom: AppStyles.spaceSm),
              child: Text(
                group.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            // ---- Trip cards -------------------------------------------
            for (var i = 0; i < group.trips.length; i++) ...[
              _TripCard(
                trip: group.trips[i],
                timeLabel: _formatTime(group.trips[i].startTime),
              ),
              if (i < group.trips.length - 1)
                const Divider(
                    height: 1, thickness: 0.5, color: AppColors.border),
            ],
          ],
        );
      },
    );
  }
}

/// A single ride-history tile — three rows of meta plus a right-aligned cost.
class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.timeLabel});

  final Trip trip;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final duration = trip.durationMin ?? 0;
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppStyles.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        onTap: () {
          // Future hook: open the ride-detail screen for this trip.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Открываю детали поездки…'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppStyles.spaceLg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppStyles.radiusSm),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: time (left) + cost (right).
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${trip.cost ?? 0}сум',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Row 2: scooter info.
              Row(
                children: [
                  const Icon(Icons.electric_scooter,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Swift Neo · ${trip.scooterId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Row 3: duration + (optional) distance.
              Text(
                '$duration мин',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
