// update_provider.dart — Riverpod state for auto-update.
//
// Exposes [updateStateProvider] and [updateInfoProvider] so the UI can
// react to update availability and track download progress.

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import '../../services/update_service.dart';

/// Singleton [UpdateService].
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

/// Current update state.
final updateStateProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  return UpdateNotifier(ref);
});

/// Info about the available update (version, download URL, notes).
final updateInfoProvider = Provider<UpdateInfo?>((ref) {
  return ref.watch(updateStateProvider.notifier).info;
});

/// Download progress 0.0–1.0. `-1` when not downloading.
final updateProgressProvider = StateProvider<double>((ref) => -1);

/// Controller for the update flow.
class UpdateNotifier extends StateNotifier<UpdateState> {
  UpdateNotifier(this._ref) : super(UpdateState.idle);

  final Ref _ref;
  UpdateInfo? info;
  String? errorMessage;

  /// Checks GitHub for a newer release. Safe to call multiple times.
  Future<void> check() async {
    state = UpdateState.checking;
    final result = await _ref.read(updateServiceProvider).checkForUpdate();
    state = result.state;
    info = result.info;
    errorMessage = result.error;
  }

  /// Downloads the installer and launches it. Updates [updateProgressProvider]
  /// as bytes stream in.
  Future<void> downloadAndInstall() async {
    if (info == null) return;
    state = UpdateState.downloading;
    _ref.read(updateProgressProvider.notifier).state = 0.0;
    try {
      final filePath = await _ref.read(updateServiceProvider).downloadAndInstall(
        info!.downloadUrl,
        info!.fileName,
        onProgress: (p) {
          _ref.read(updateProgressProvider.notifier).state = p;
        },
      );
      state = UpdateState.installing;
      // Launch the installer / APK.
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // On desktop, run the installer directly.
        await Process.run(filePath, []);
      } else {
        // On Android, open the .apk with the system installer.
        await OpenFile.open(filePath);
      }
    } catch (e) {
      state = UpdateState.error;
      errorMessage = 'Ошибка: $e';
    }
  }

  /// Dismisses the update notification (state → idle).
  void dismiss() {
    state = UpdateState.idle;
    info = null;
  }
}
