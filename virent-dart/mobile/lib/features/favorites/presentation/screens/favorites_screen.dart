import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart'
    show apiClientProvider;
import '../../data/models/favorite_model.dart';
import '../../data/repositories/favorites_repository.dart';

/// Riverpod-провайдер для [FavoritesRepository].
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.read(apiClientProvider));
});

/// Async-список сохранённых мест пользователя.
final favoritesProvider =
    FutureProvider.autoDispose<List<Favorite>>((ref) async {
  return ref.read(favoritesRepositoryProvider).getFavorites();
});

/// Избранное — список сохранённых мест.
///
/// Стиль референса: AppBar с кнопкой «назад» и заголовком «Избранное»,
/// список карточек (белый фон, 8px скругление, padding 16) с иконкой локации,
/// названием 16px Medium, адресом 14px серый и шевроном вправо. Пустое
/// состояние «Нет сохранённых мест». FAB «+» для добавления.
///
/// Бизнес-логика, провайдеры, модель и форма добавления сохранены без
/// изменений — переписан только UI списка.
class FavoritesScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  bool _showAdd = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (_showAdd) {
              setState(() => _showAdd = false);
            } else {
              context.pop();
            }
          },
        ),
        title: const Text(
          'Избранное',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
      floatingActionButton: _showAdd
          ? null
          : FloatingActionButton(
              onPressed: () => setState(() => _showAdd = true),
              backgroundColor: AppColors.primaryCta,
              foregroundColor: AppColors.black,
              elevation: 2,
              child: const Icon(Icons.add),
            ),
      body: _showAdd
          ? _AddFavoriteForm(
              onCancel: () => setState(() => _showAdd = false),
              onSaved: () {
                setState(() => _showAdd = false);
                ref.invalidate(favoritesProvider);
              },
            )
          : async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(favoritesProvider),
              ),
              data: (favorites) {
                if (favorites.isEmpty) {
                  return _EmptyState(
                    onAdd: () => setState(() => _showAdd = true),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(favoritesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppStyles.spaceLg, AppStyles.spaceSm, AppStyles.spaceLg, 96),
                    itemCount: favorites.length,
                    itemBuilder: (_, i) {
                      final f = favorites[i];
                      return Dismissible(
                        key: ValueKey(f.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: AppStyles.spaceSm),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius:
                                BorderRadius.circular(AppStyles.radiusSm),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) => _confirmDelete(f),
                        onDismissed: (_) async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref
                                .read(favoritesRepositoryProvider)
                                .deleteFavorite(f.id);
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('«${f.name}» удалено')),
                              );
                            }
                            ref.invalidate(favoritesProvider);
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Ошибка: $e')),
                              );
                              ref.invalidate(favoritesProvider);
                            }
                          }
                        },
                        child: _FavoriteTile(
                          favorite: f,
                          onTap: () => _showOnMap(context, f),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<bool?> _confirmDelete(Favorite f) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить место?'),
        content: Text('«${f.name}» будет удалено из сохранённых мест.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showOnMap(BuildContext context, Favorite f) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Маршрут до «${f.name}»'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }
}

/// Карточка сохранённого места — иконка локации, название, адрес, шеврон.
class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.favorite, required this.onTap});

  final Favorite favorite;
  final VoidCallback onTap;

  String _formatCoords() =>
      '${favorite.latitude.toStringAsFixed(4)}, ${favorite.longitude.toStringAsFixed(4)}';

  @override
  Widget build(BuildContext context) {
    final address = (favorite.address != null && favorite.address!.isNotEmpty)
        ? favorite.address!
        : _formatCoords();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusSm),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppStyles.spaceSm),
        padding: const EdgeInsets.all(AppStyles.spaceLg),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppStyles.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.place_outlined,
              color: AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: AppStyles.spaceLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppStyles.spaceSm),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 24),
          ],
        ),
      ),
    );
  }
}

/// Форма добавления места — сохранена из оригинала, переведена на русский.
class _AddFavoriteForm extends ConsumerStatefulWidget {
  const _AddFavoriteForm({required this.onCancel, required this.onSaved});

  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  ConsumerState<_AddFavoriteForm> createState() => _AddFavoriteFormState();
}

class _AddFavoriteFormState extends ConsumerState<_AddFavoriteForm> {
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _addressController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    if (name.isEmpty || lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Введите название и корректные координаты')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(favoritesRepositoryProvider).addFavorite(
            name: name,
            latitude: lat,
            longitude: lng,
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('«$name» добавлено в избранное')),
        );
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Добавить место',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: AppStyles.spaceSm),
          const Text(
            'Сохраните часто посещаемое место, чтобы строить маршрут в одно '
            'нажатие.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: AppStyles.spaceXl),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Название',
              hintText: 'Дом, Работа, Спортзал…',
              prefixIcon: Icon(Icons.label_outline),
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: AppStyles.spaceMd),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latController,
                  decoration: const InputDecoration(
                    labelText: 'Широта',
                    prefixIcon: Icon(Icons.my_location),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                ),
              ),
              const SizedBox(width: AppStyles.spaceMd),
              Expanded(
                child: TextField(
                  controller: _lngController,
                  decoration: const InputDecoration(
                    labelText: 'Долгота',
                    prefixIcon: Icon(Icons.explore),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceMd),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Адрес (необязательно)',
              prefixIcon: Icon(Icons.place_outlined),
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppStyles.spaceXl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusSm),
                    ),
                  ),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppStyles.spaceMd),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryCta,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusSm),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.black),
                        )
                      : const Text(
                          'Сохранить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Пустое состояние — «Нет сохранённых мест».
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_border_rounded,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppStyles.spaceLg),
            const Text(
              'Нет сохранённых мест',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: AppStyles.spaceSm),
            const Text(
              'Добавьте часто посещаемые места, чтобы быстро строить маршрут',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: AppStyles.spaceXl),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Добавить место'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryCta,
                foregroundColor: AppColors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Состояние ошибки.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppColors.textMuted),
            const SizedBox(height: AppStyles.spaceMd),
            const Text(
              'Не удалось загрузить места',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spaceSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: AppStyles.spaceLg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
