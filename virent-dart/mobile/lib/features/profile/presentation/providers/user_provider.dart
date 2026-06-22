import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/configs/services/api_client.dart';
import '../../../../core/configs/services/storage_service.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/profile_repository.dart';

/// Provider exposing the singleton [ApiClient] to the profile layer.
final profileApiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Provider for the [StorageService] used by the profile layer.
final profileStorageProvider =
    Provider<StorageService>((ref) => StorageService());

/// Provider for the [ProfileRepository] implementation.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    ref.watch(profileApiClientProvider),
    ref.watch(profileStorageProvider),
  );
});

/// Immutable view-state for the profile screen.
class UserState {
  /// The currently authenticated user, `null` until the first fetch
  /// completes.
  final UserProfileModel? user;

  /// `true` while the profile is being fetched or refreshed.
  final bool loading;

  /// `true` while an update / password-change is in flight.
  final bool actionInProgress;

  /// Human readable message — informational, error or success — `null` when
  /// the last operation produced no message.
  final String? message;

  /// `true` when [message] represents an error.
  final bool isError;

  /// `true` when [message] represents a success.
  final bool isSuccess;

  /// Creates a [UserState].
  const UserState({
    this.user,
    this.loading = false,
    this.actionInProgress = false,
    this.message,
    this.isError = false,
    this.isSuccess = false,
  });

  /// Returns a copy with the given fields overridden.
  UserState copyWith({
    UserProfileModel? user,
    bool? loading,
    bool? actionInProgress,
    String? message,
    bool? isError,
    bool? isSuccess,
    bool clearMessage = false,
  }) {
    return UserState(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  String toString() =>
      'UserState(user: $user, loading: $loading, '
      'actionInProgress: $actionInProgress, isError: $isError)';
}

/// Riverpod notifier that drives the profile screen.
///
/// Exposes:
/// - [refresh]        — re-fetch the profile from the server.
/// - [updateProfile]  — patch name / email.
/// - [changePassword] — exchange the current password for a new one.
class UserNotifier extends StateNotifier<UserState> {
  final ProfileRepository _repo;

  /// Creates a [UserNotifier] bound to [repository].
  UserNotifier(this._repo) : super(const UserState()) {
    refresh();
  }

  /// Re-fetches the profile from the server.
  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearMessage: true);
    try {
      final user = await _repo.getProfile();
      if (!mounted) return;
      state = state.copyWith(user: user, loading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        message: e.toString(),
        isError: true,
      );
    }
  }

  /// Updates the profile with the given fields.
  ///
  /// Returns `true` on success.
  Future<bool> updateProfile({String? name, String? email}) async {
    state = state.copyWith(actionInProgress: true, clearMessage: true);
    try {
      final user = await _repo.updateProfile(name: name, email: email);
      if (!mounted) return false;
      state = state.copyWith(
        user: user,
        actionInProgress: false,
        message: 'Profile updated',
        isSuccess: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        actionInProgress: false,
        message: e.toString(),
        isError: true,
      );
      return false;
    }
  }

  /// Changes the user's password.
  ///
  /// Returns `true` on success.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(actionInProgress: true, clearMessage: true);
    try {
      await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!mounted) return false;
      state = state.copyWith(
        actionInProgress: false,
        message: 'Password changed',
        isSuccess: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        actionInProgress: false,
        message: e.toString(),
        isError: true,
      );
      return false;
    }
  }

  /// Clears any inline message (used by the UI when dismissing a banner).
  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}

/// Provider exposing the [UserState] and its notifier.
///
/// Named `userProvider` to match the BarqScoot API the rest of the app
/// expects.
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.watch(profileRepositoryProvider));
});
