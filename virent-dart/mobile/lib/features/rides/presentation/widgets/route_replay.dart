import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/configs/theme/app_colors.dart';

/// Route replay — animates drawing a polyline route on a `FlutterMap`.
///
/// Takes a list of [points] (chronological, start → end) and progressively
/// reveals the polyline over [duration] (default 3 seconds). At the end of
/// the animation two markers are pinned: a green start marker and a red
/// end marker, each carrying a small battery glyph so the rider can see
/// the battery delta at a glance.
///
/// The widget is self-contained: pass it the points and the map controller,
/// and it will manage its own animation controller + ticker.
class RouteReplay extends StatefulWidget {
  /// Creates a [RouteReplay].
  const RouteReplay({
    super.key,
    required this.points,
    this.duration = const Duration(seconds: 3),
    this.startBattery = 100,
    this.endBattery = 45,
    this.onComplete,
  });

  /// Chronological list of route points (start first, end last).
  final List<LatLng> points;

  /// Animation duration. Defaults to 3 seconds.
  final Duration duration;

  /// Battery percentage at the start of the ride (0–100).
  final int startBattery;

  /// Battery percentage at the end of the ride (0–100).
  final int endBattery;

  /// Invoked once when the polyline has finished drawing.
  final VoidCallback? onComplete;

  @override
  State<RouteReplay> createState() => _RouteReplayState();
}

class _RouteReplayState extends State<RouteReplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
    // Kick off the animation on the next frame so the map has time to lay
    // out before we start revealing the polyline.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Re-runs the animation from the start.
  void replay() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final visible = _visiblePoints(_progress.value);
        return Stack(
          children: [
            // Polyline layer.
            PolylineLayer(
              polylines: [
                Polyline(
                  points: visible,
                  color: AppColors.primary,
                  strokeWidth: 5.0,
                ),
              ],
            ),
            // Start marker — always visible from t=0.
            if (widget.points.isNotEmpty)
              MarkerLayer(
                markers: [
                  _buildMarker(
                    point: widget.points.first,
                    color: AppColors.success,
                    label: 'Start',
                    battery: widget.startBattery,
                  ),
                ],
              ),
            // End marker — only once the animation has finished.
            if (_progress.value >= 0.999 && widget.points.length > 1)
              MarkerLayer(
                markers: [
                  _buildMarker(
                    point: widget.points.last,
                    color: AppColors.danger,
                    label: 'End',
                    battery: widget.endBattery,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  /// Returns the slice of [widget.points] that should be visible at the
  /// supplied animation [progress] (0.0 → 1.0).
  ///
  /// The last point is interpolated between the two surrounding points so
  /// the line tip moves smoothly rather than jumping between vertices.
  List<LatLng> _visiblePoints(double progress) {
    final points = widget.points;
    if (points.length < 2) return points;

    final totalSegments = points.length - 1;
    final target = (totalSegments * progress).clamp(0, totalSegments.toDouble());
    final whole = target.floor();
    final fraction = target - whole;

    final visible = points.sublist(0, whole + 1);
    if (whole < totalSegments) {
      final a = points[whole];
      final b = points[whole + 1];
      visible.add(LatLng(
        a.latitude + (b.latitude - a.latitude) * fraction,
        a.longitude + (b.longitude - a.longitude) * fraction,
      ));
    }
    return visible;
  }

  /// Builds a circular marker with a battery glyph inside.
  Marker _buildMarker({
    required LatLng point,
    required Color color,
    required String label,
    required int battery,
  }) {
    return Marker(
      point: point,
      width: 44,
      height: 56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
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
            child: Icon(
              Icons.battery_charging_full,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              '$label $battery%',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
