import 'package:flutter/material.dart';

import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';

/// Bottom sheet form used to type in a scooter id manually when the QR
/// code is damaged or the camera cannot focus.
///
/// Ported from BarqScoot's `ManualEntryForm`. Calls [onSubmit] with the
/// trimmed value when the rider taps "Unlock".
class ManualEntryForm extends StatefulWidget {
  /// Creates a [ManualEntryForm].
  const ManualEntryForm({
    super.key,
    required this.onSubmit,
    required this.onClose,
  });

  /// Invoked with the trimmed scooter id when the rider submits.
  final ValueChanged<String> onSubmit;

  /// Invoked when the rider dismisses the form without submitting.
  final VoidCallback onClose;

  @override
  State<ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<ManualEntryForm> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    final value = _controller.text.trim();
    final valid = value.isNotEmpty && value.length >= 2;
    if (valid != _isValid) {
      setState(() => _isValid = valid);
    }
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty || value.length < 2) return;
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacing, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Enter scooter ID',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacing, vertical: 4),
              child: Text(
                'Find the scooter id printed on the handlebar or under the deck. It usually starts with "V-".',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacing, vertical: 8),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'e.g. V-001',
                  hintStyle: theme.textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textMuted),
                  prefixIcon:
                      const Icon(Icons.electric_scooter, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppStyles.spacing, 4, AppStyles.spacing, AppStyles.spacing),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isValid ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppStyles.borderRadius),
                    ),
                  ),
                  icon: const Icon(Icons.lock_open),
                  label: const Text(
                    'Unlock scooter',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
