import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/configs/services/api_client.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/wallet_repository.dart';

/// Provider exposing the singleton [ApiClient] to the wallet layer.
///
/// Defined here so the wallet feature owns its own DI graph — other features
/// continue to use the home feature's `VirentRepository` for the same client.
final walletApiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Provider for the [WalletRepository] implementation.
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(walletApiClientProvider));
});

/// Immutable view-state for the wallet screen.
class WalletState {
  /// Current wallet balance in the smallest currency unit (tiyin / UZS).
  final int balance;

  /// Most recent transactions, newest first.
  final List<TransactionModel> transactions;

  /// `true` while a network request is in flight.
  final bool loading;

  /// `true` while a top-up / promo redemption is processing.
  final bool actionInProgress;

  /// Human readable error message, `null` when the last operation succeeded.
  final String? error;

  /// Quick-access balance-change indicator for the gradient card subtitle.
  ///
  /// Computed from the first transaction with a non-zero amount — `null` when
  /// there are no transactions yet.
  final TransactionModel? lastChange;

  /// Creates a [WalletState].
  const WalletState({
    this.balance = 0,
    this.transactions = const <TransactionModel>[],
    this.loading = false,
    this.actionInProgress = false,
    this.error,
    this.lastChange,
  });

  /// Returns a copy with the given fields overridden.
  WalletState copyWith({
    int? balance,
    List<TransactionModel>? transactions,
    bool? loading,
    bool? actionInProgress,
    String? error,
    TransactionModel? lastChange,
    bool clearError = false,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      loading: loading ?? this.loading,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      error: clearError ? null : (error ?? this.error),
      lastChange: lastChange ?? this.lastChange,
    );
  }

  @override
  String toString() =>
      'WalletState(balance: $balance, txCount: ${transactions.length}, '
      'loading: $loading, actionInProgress: $actionInProgress, error: $error)';
}

/// Riverpod notifier that drives the wallet screen.
///
/// Exposes:
/// - [refresh]   — re-fetch balance + transactions.
/// - [topUp]     — credit funds via a payment provider.
/// - [applyPromo] — redeem a promo code.
class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repo;

  /// Creates a [WalletNotifier] bound to [repository].
  WalletNotifier(this._repo) : super(const WalletState()) {
    refresh();
  }

  /// Re-fetches the balance and the recent transactions.
  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final balance = await _repo.getBalance();
      final txs = await _repo.getTransactions();
      if (!mounted) return;
      state = state.copyWith(
        balance: balance,
        transactions: txs,
        lastChange: txs.isNotEmpty ? txs.first : null,
        loading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  /// Credits [amount] via [provider] and refreshes the balance.
  ///
  /// Returns `true` on success. The caller is responsible for showing a
  /// snackbar — the notifier only updates the state.
  Future<bool> topUp(int amount, {String provider = 'click'}) async {
    state = state.copyWith(actionInProgress: true, clearError: true);
    try {
      final newBalance =
          await _repo.topUp(amount, provider: provider);
      final txs = await _repo.getTransactions();
      if (!mounted) return false;
      state = state.copyWith(
        balance: newBalance,
        transactions: txs,
        lastChange: txs.isNotEmpty ? txs.first : null,
        actionInProgress: false,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        actionInProgress: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Redeems [code] for wallet credit and refreshes the balance.
  ///
  /// Returns the granted bonus amount, or `0` when the redemption failed.
  Future<int> applyPromo(String code) async {
    state = state.copyWith(actionInProgress: true, clearError: true);
    try {
      final granted = await _repo.applyPromo(code);
      final balance = await _repo.getBalance();
      final txs = await _repo.getTransactions();
      if (!mounted) return 0;
      state = state.copyWith(
        balance: balance,
        transactions: txs,
        lastChange: txs.isNotEmpty ? txs.first : null,
        actionInProgress: false,
      );
      return granted;
    } catch (e) {
      if (!mounted) return 0;
      state = state.copyWith(
        actionInProgress: false,
        error: e.toString(),
      );
      return 0;
    }
  }
}

/// Provider exposing the [WalletState] and its notifier.
final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref.watch(walletRepositoryProvider));
});
