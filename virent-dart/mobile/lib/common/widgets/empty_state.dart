// empty_state.dart — reusable empty state.
//
// Shown by list / history / wallet screens when there is no data yet.
// Composed of an icon, a short title, an optional description and an
// optional primary action button. Uses Virent design tokens.

import 'package:flutter/material.dart';
import '../../core/configs/theme/app_colors.dart';

/// A full-widget empty state with an optional call-to-action.
class EmptyState extends StatelessWidget {
  /// Material icon used as the hero illustration.
  final IconData icon;

  /// Short headline, e.g. "No trips yet".
  final String title;

  /// Optional supporting description.
  final String? description;

  /// Label for the optional primary action button.
  final String? actionLabel;

  /// Optional icon shown on the action button.
  final IconData? actionIcon;

  /// Invoked when the action button is tapped.
  final VoidCallback? onAction;

  /// Creates an empty state.
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: actionIcon != null
                    ? Icon(actionIcon)
                    : const SizedBox.shrink(),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
