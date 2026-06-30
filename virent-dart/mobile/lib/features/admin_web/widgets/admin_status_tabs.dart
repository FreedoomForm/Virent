// admin_status_tabs.dart — Status badge row for admin panel pages.
//
// Renders a horizontally scrollable row of status badges (e.g. "Всего",
// "Активные", "Завершённые") with live counts. Each badge is tappable and
// can be wired to a tab/filter callback in the parent page.

import 'package:flutter/material.dart';

/// One status tab descriptor used by [AdminStatusTabsRow].
class AdminStatusBadge {
  const AdminStatusBadge({
    required this.label,
    required this.count,
    this.color = const Color(0xFF7C69EF),
    this.active = false,
    this.onTap,
  });

  /// Human-readable label (e.g. "Всего", "Активные").
  final String label;

  /// Counter value rendered next to the label.
  final int count;

  /// Accent colour for the badge.
  final Color color;

  /// Whether this tab is currently selected/active.
  final bool active;

  /// Optional tap handler. When null, the badge is non-interactive.
  final VoidCallback? onTap;
}

/// A horizontal row of [AdminStatusBadge] widgets.
///
/// Wraps in a [SingleChildScrollView] so wide sets of tabs never overflow.
class AdminStatusTabsRow extends StatelessWidget {
  const AdminStatusTabsRow({
    super.key,
    required this.badges,
    this.onTapBadge,
  });

  /// Ordered list of badges to render.
  final List<AdminStatusBadge> badges;

  /// Optional callback invoked with the tapped badge index when an
  /// individual badge does not declare its own [AdminStatusBadge.onTap].
  final void Function(int index)? onTapBadge;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: badges.asMap().entries.map((entry) {
            final i = entry.key;
            final b = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: b.onTap ?? (onTapBadge != null ? () => onTapBadge!(i) : null),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: b.active ? b.color : const Color(0xFFF1F4F8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: b.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        b.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: b.active ? Colors.white : const Color(0xFF1B2A4E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: b.active
                              ? Colors.white.withValues(alpha: 0.25)
                              : b.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${b.count}',
                          style: TextStyle(
                            fontSize: 11,
                            color: b.active ? Colors.white : b.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
