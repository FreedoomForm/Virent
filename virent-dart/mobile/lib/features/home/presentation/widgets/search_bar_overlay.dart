import 'package:flutter/material.dart';

import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';

/// A single address prediction surfaced by the autocomplete search.
@immutable
class AddressSuggestion {
  /// Creates an [AddressSuggestion].
  const AddressSuggestion({
    required this.id,
    required this.primary,
    required this.secondary,
    required this.lat,
    required this.lng,
    this.isRecent = false,
  });

  /// Stable identifier (typically the place_id from the geocoder).
  final String id;

  /// Main display line — usually the street name.
  final String primary;

  /// Secondary display line — city, district or postal code.
  final String secondary;

  /// Latitude of the suggested location.
  final double lat;

  /// Longitude of the suggested location.
  final double lng;

  /// `true` when this entry is sourced from the rider's recent locations
  /// rather than a live geocode. Renders a history icon instead of a pin.
  final bool isRecent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AddressSuggestion && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Inline search bar pinned to the top of the home map.
///
/// Renders a rounded, white, shadow-elevated pill with the placeholder
/// `"Куда едем?"` (Where to?). When the rider taps the bar an overlay panel
/// slides down over the map listing recent destinations and live address
/// autocomplete results from [onSearch].
///
/// The widget is controlled via [recentLocations], [onSearch] and
/// [onSuggestionSelected]. It is intentionally stateful so callers can drop
/// it into a `Stack` without wiring up their own overlay controller.
///
/// Ported from the Swift competitor's `SearchBarOverlay` and restyled with
/// Virent design tokens (16dp radius, primary colour #3489FF).
class SearchBarOverlay extends StatefulWidget {
  /// Creates a [SearchBarOverlay].
  const SearchBarOverlay({
    super.key,
    this.recentLocations = const [],
    this.onSearch,
    this.onSuggestionSelected,
    this.onBackTapped,
    this.hintText = 'Куда едем?',
    this.autocompleteDebounce = const Duration(milliseconds: 300),
  });

  /// The rider's most recently used destinations. Shown above the live
  /// autocomplete results when the bar is expanded.
  final List<AddressSuggestion> recentLocations;

  /// Invoked with the current query string. The implementation should call a
  /// geocoding service and return a list of [AddressSuggestion]s. The
  /// callback is debounced by [autocompleteDebounce].
  final Future<List<AddressSuggestion>> Function(String query)? onSearch;

  /// Invoked when the rider picks a suggestion — typically the parent
  /// navigates to [RoutePlanningScreen] with the chosen coordinates.
  final ValueChanged<AddressSuggestion>? onSuggestionSelected;

  /// Invoked when the rider taps the back chevron while the overlay is open.
  final VoidCallback? onBackTapped;

  /// Placeholder text shown in the collapsed search bar.
  final String hintText;

  /// Debounce window for [onSearch]. Defaults to 300 ms.
  final Duration autocompleteDebounce;

  @override
  State<SearchBarOverlay> createState() => _SearchBarOverlayState();
}

class _SearchBarOverlayState extends State<SearchBarOverlay> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _expanded = false;
  bool _loading = false;
  List<AddressSuggestion> _results = const [];
  Future<List<AddressSuggestion>>? _lastFuture;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onQueryChanged() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      _lastFuture = null;
      return;
    }
    if (widget.onSearch == null) return;

    setState(() => _loading = true);

    // Debounce: wait for the user to stop typing before firing the request.
    await Future<void>.delayed(widget.autocompleteDebounce);
    if (!mounted) return;
    if (_controller.text.trim() != query) return;

    final future = widget.onSearch!(query);
    _lastFuture = future;
    try {
      final results = await future;
      if (!mounted) return;
      // Drop the result if a newer request superseded this one.
      if (_lastFuture != future) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_lastFuture != future) return;
      setState(() {
        _results = const [];
        _loading = false;
      });
    }
  }

  void _expand() {
    setState(() => _expanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _collapse() {
    setState(() {
      _expanded = false;
      _controller.clear();
      _results = const [];
    });
    _focusNode.unfocus();
  }

  void _select(AddressSuggestion suggestion) {
    widget.onSuggestionSelected?.call(suggestion);
    _collapse();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacing, vertical: 8),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded ? _buildExpanded() : _buildCollapsed(),
        ),
      ),
    );
  }

  // ---- Collapsed bar --------------------------------------------------------

  Widget _buildCollapsed() {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      elevation: 4,
      shadowColor: const Color(0x14000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        onTap: _expand,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.search,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.hintText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const Icon(Icons.tune,
                  color: AppColors.textMuted, size: 20,
                  semanticLabel: 'Filters'),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Expanded panel -------------------------------------------------------

  Widget _buildExpanded() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      elevation: 6,
      shadowColor: const Color(0x1F000000),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchRow(),
            const Divider(height: 16, color: AppColors.border),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow() {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            _collapse();
            widget.onBackTapped?.call();
          },
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              isDense: true,
              prefixIcon: const Icon(Icons.search,
                  color: AppColors.primary, size: 20),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _controller.clear(),
                    )
                  : null,
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
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    // Live autocomplete results take precedence once the rider starts typing.
    if (_controller.text.trim().isNotEmpty) {
      if (_results.isEmpty) {
        return _EmptyState(
          icon: Icons.location_off,
          message: 'Адреса не найдены',
        );
      }
      return _SuggestionList(
        suggestions: _results,
        onTap: _select,
      );
    }

    // No query yet — show recent locations.
    if (widget.recentLocations.isEmpty) {
      return _EmptyState(
        icon: Icons.history,
        message: 'Недавних адресов пока нет',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Недавние',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ),
        _SuggestionList(
          suggestions: widget.recentLocations,
          onTap: _select,
        ),
      ],
    );
  }
}

/// Renders a list of [AddressSuggestion] tiles.
class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.suggestions, required this.onTap});

  final List<AddressSuggestion> suggestions;
  final ValueChanged<AddressSuggestion> onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: AppColors.border,
        ),
        itemBuilder: (context, index) {
          final s = suggestions[index];
          return _SuggestionTile(suggestion: s, onTap: () => onTap(s));
        },
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, required this.onTap});

  final AddressSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppStyles.borderRadiusSm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Icon(
              suggestion.isRecent
                  ? Icons.history
                  : Icons.location_on_outlined,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion.secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
