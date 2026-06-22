// admin_shortcut_grid.dart — reusable grid widget for admin home screen.
//
// Renders a responsive grid of admin shortcut tiles. Each tile is an icon in
// a coloured circle with a label below; tapping the tile navigates to the
// given [AdminShortcut.route] via `context.push`.
//
// Layout:
//   - mobile  (< 600px)  : 3 columns
//   - tablet  (600-899)  : 4 columns
//   - desktop (>= 900px) : 5 columns
//
// Each tile accepts an optional [AdminShortcut.badge] — a small count (e.g.
// open support tickets) rendered in the top-right corner of the tile.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';

/// A single admin shortcut descriptor rendered by [AdminShortcutGrid].
@immutable
class AdminShortcut {
  /// Creates an [AdminShortcut].
  const AdminShortcut({
    required this.icon,
    required this.label,
    required this.route,
    this.color = AppColors.primary,
    this.badge,
  });

  /// Material icon shown inside the coloured circle.
  final IconData icon;

  /// Short label rendered under the icon. Should be ≤ 12 characters so it
  /// never wraps on a 3-column mobile grid.
  final String label;

  /// Route pushed onto the navigator stack when the tile is tapped.
  final String route;

  /// Accent colour used for the icon + the circle background.
  final Color color;

  /// Optional count badge rendered in the top-right corner. Pass `null` or
  /// `0` to hide the badge.
  final int? badge;
}

/// Responsive grid of admin shortcuts.
///
/// Wraps a [GridView] in a shrink-wrap so it can be embedded inside any
/// scrollable parent. The column count is derived from the available width
/// (3 on mobile, 4 on tablet, 5 on desktop) — pass [childAspectRatio] to
/// adjust the tile shape.
class AdminShortcutGrid extends StatelessWidget {
  /// Creates an [AdminShortcutGrid].
  const AdminShortcutGrid({
    required this.items,
    super.key,
    this.childAspectRatio = 0.92,
    this.onTap,
  });

  /// Shortcut descriptors to render.
  final List<AdminShortcut> items;

  /// Width / height ratio of each tile. Default `0.92` keeps tiles roughly
  /// square while leaving room for a 2-line label.
  final double childAspectRatio;

  /// Optional tap handler. Defaults to `context.push(item.route)`.
  final void Function(BuildContext context, AdminShortcut item)? onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Pick a sensible cross-axis count based on the available width — this
    // keeps the tiles from getting too cramped on large tablets.
    final crossAxisCount = width >= 900
        ? 5
        : width >= 600
            ? 4
            : 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _AdminShortcutTile(
          shortcut: item,
          onTap: () {
            if (onTap != null) {
              onTap!(context, item);
            } else if (item.route.isNotEmpty) {
              context.push(item.route);
            }
          },
        );
      },
    );
  }
}

/// Renders a single shortcut tile.
class _AdminShortcutTile extends StatelessWidget {
  const _AdminShortcutTile({required this.shortcut, required this.onTap});

  final AdminShortcut shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBadge = (shortcut.badge ?? 0) > 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: shortcut.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(shortcut.icon, color: shortcut.color, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      shortcut.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
              if (showBadge)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      shortcut.badge! > 99 ? '99+' : '${shortcut.badge}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
