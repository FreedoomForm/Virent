import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/configs/services/api_client.dart';
import '../../data/models/promo_code_model.dart';
import '../../data/repositories/payment_repository.dart';

/// Provider exposing the singleton [ApiClient] to the payment layer.
final paymentApiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Provider for the [PaymentRepository] implementation.
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.watch(paymentApiClientProvider));
});

/// Immutable view-state for the promo-code flow.
class PromoState {
  /// The promo code currently entered in the text field (uppercase).
  final String enteredCode;

  /// The most recently validated promo code, `null` when none is active.
  final PromoCodeModel? activePromo;

  /// `true` while a validation request is in flight.
  final bool validating;

  /// `true` while a payment is being processed.
  final bool paying;

  /// Human readable message — informational, error or success — `null` when
  /// the last operation produced no message.
  final String? message;

  /// `true` when [message] represents an error.
  final bool isError;

  /// `true` when [message] represents a success.
  final bool isSuccess;

  /// Creates a [PromoState].
  const PromoState({
    this.enteredCode = '',
    this.activePromo,
    this.validating = false,
    this.paying = false,
    this.message,
    this.isError = false,
    this.isSuccess = false,
  });

  /// `true` when a promo code is currently applied.
  bool get hasActivePromo => activePromo != null;

  /// Returns a copy with the given fields overridden.
  PromoState copyWith({
    String? enteredCode,
    PromoCodeModel? activePromo,
    bool? validating,
    bool? paying,
    String? message,
    bool? isError,
    bool? isSuccess,
    bool clearMessage = false,
    bool clearPromo = false,
  }) {
    return PromoState(
      enteredCode: enteredCode ?? this.enteredCode,
      activePromo: clearPromo ? null : (activePromo ?? this.activePromo),
      validating: validating ?? this.validating,
      paying: paying ?? this.paying,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  String toString() =>
      'PromoState(enteredCode: $enteredCode, hasActivePromo: $hasActivePromo, '
      'validating: $validating, paying: $paying, isError: $isError)';
}

/// Riverpod notifier that drives the promo-code UI on the payment screen.
///
/// Exposes:
/// - [setEnteredCode] — update the text field value.
/// - [validatePromo]  — confirm the entered code against [total].
/// - [applyPromo]     — alias for [validatePromo] used by the UI button.
/// - [clearPromo]     — remove the active promo.
/// - [processPayment] — settle a ride via the given method.
class PromoNotifier extends StateNotifier<PromoState> {
  final PaymentRepository _repo;

  /// Creates a [PromoNotifier] bound to [repository].
  PromoNotifier(this._repo) : super(const PromoState());

  /// Updates the entered code without triggering a request.
  void setEnteredCode(String code) {
    state = state.copyWith(
      enteredCode: code.toUpperCase(),
      clearMessage: true,
    );
  }

  /// Validates the currently entered code against [total].
  Future<bool> validatePromo(double total) async {
    final code = state.enteredCode.trim();
    if (code.isEmpty) {
      state = state.copyWith(message: 'Enter a promo code', isError: true);
      return false;
    }
    state = state.copyWith(validating: true, clearMessage: true);
    try {
      final promo = await _repo.validatePromo(code, total);
      if (!promo.isValid) {
        state = state.copyWith(
          validating: false,
          message: 'This promo code is no longer valid',
          isError: true,
          clearPromo: true,
        );
        return false;
      }
      state = state.copyWith(
        validating: false,
        activePromo: promo,
        message: promo.description.isEmpty
            ? 'Promo code applied'
            : promo.description,
        isSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        validating: false,
        message: e.toString(),
        isError: true,
        clearPromo: true,
      );
      return false;
    }
  }

  /// Alias for [validatePromo] — kept for parity with the BarqScoot API.
  Future<bool> applyPromo(double total) => validatePromo(total);

  /// Removes the active promo code.
  void clearPromo() {
    state = state.copyWith(
      clearPromo: true,
      clearMessage: true,
      enteredCode: '',
    );
  }

  /// Settles [rideId] using [method] with the current promo applied.
  ///
  /// Returns the charged amount (in UZS) on success, or `null` on failure.
  Future<int?> processPayment({
    required String rideId,
    required String method,
    required double total,
  }) async {
    state = state.copyWith(paying: true, clearMessage: true);
    try {
      final charged = await _repo.processPayment(
        rideId: rideId,
        method: method,
        total: total,
        promoCode: state.activePromo?.code ?? '',
      );
      state = state.copyWith(
        paying: false,
        message: 'Payment successful',
        isSuccess: true,
      );
      return charged;
    } catch (e) {
      state = state.copyWith(
        paying: false,
        message: e.toString(),
        isError: true,
      );
      return null;
    }
  }
}

/// Provider exposing the [PromoState] and its notifier.
final promoProvider =
    StateNotifierProvider<PromoNotifier, PromoState>((ref) {
  return PromoNotifier(ref.watch(paymentRepositoryProvider));
});
