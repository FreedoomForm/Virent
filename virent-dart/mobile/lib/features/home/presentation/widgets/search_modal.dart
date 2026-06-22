import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../providers/scooter_provider.dart';
import '../../data/models/scooter_model.dart';

/// Modal bottom sheet used to search the nearby scooter list by name.
///
/// Ported from BarqScoot's `SearchModal` and extended with live filtering
/// against the [scooterNotifierProvider] state.
class SearchModal extends ConsumerStatefulWidget {
  /// Creates a [SearchModal].
  const SearchModal({super.key});

  @override
  ConsumerState<SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends ConsumerState<SearchModal> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  bool _batteryFilter = false;
  bool _within1km = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _controller.addListener(() {
      if (mounted) {
        setState(() => _query = _controller.text.trim().toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<ScooterModel> _filter(List<ScooterModel> scooters) {
    return scooters.where((s) {
      if (!s.isAvailable) return false;
      if (_query.isNotEmpty &&
          !s.name.toLowerCase().contains(_query) &&
          !s.id.toLowerCase().contains(_query)) {
        return false;
      }
      if (_batteryFilter && s.battery <= 50) return false;
      if (_within1km && (s.distance == null || s.distance! > 1000)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(scooterNotifierProvider);
    final results = _filter(state.scooters);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
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
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Поиск по имени или номеру самоката',
                        hintStyle: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textMuted),
                        prefixIcon:
                            const Icon(Icons.search, color: AppColors.primary),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => _controller.clear(),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppStyles.borderRadius),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppStyles.borderRadius),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppStyles.borderRadius),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacing, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Заряд > 50%'),
                    selected: _batteryFilter,
                    onSelected: (v) =>
                        setState(() => _batteryFilter = v),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceAlt,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  FilterChip(
                    label: const Text('До 1 км'),
                    selected: _within1km,
                    onSelected: (v) => setState(() => _within1km = v),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceAlt,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppStyles.spacing),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off,
                                color: AppColors.textMuted, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'Самокаты не найдены',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spacing, vertical: 8),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final scooter = results[index];
                        return _SearchResultTile(
                          scooter: scooter,
                          onTap: () {
                            ref
                                .read(scooterNotifierProvider.notifier)
                                .selectScooter(scooter);
                            Navigator.of(context).maybePop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single search result row.
class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.scooter, required this.onTap});

  final ScooterModel scooter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppStyles.borderRadiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusSm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppStyles.borderRadiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.electric_scooter,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scooter.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${scooter.id}'
                      '${scooter.distance != null ? '  •  ${scooter.distance} м' : ''}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.battery_charging_full,
                size: 18,
                color: scooter.battery > 50
                    ? AppColors.success
                    : scooter.battery > 20
                        ? AppColors.warning
                        : AppColors.danger,
              ),
              const SizedBox(width: 4),
              Text(
                '${scooter.battery}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
