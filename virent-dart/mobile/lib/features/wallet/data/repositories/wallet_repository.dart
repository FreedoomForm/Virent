import '../../../../core/configs/services/api_client.dart';
import '../../../../core/error/api_exceptions.dart';
import '../models/transaction_model.dart';

/// Contract for the wallet data layer.
///
/// Defines the four operations the wallet feature needs:
/// - [getBalance]        — read the current wallet balance.
/// - [getTransactions]   — list the recent ledger entries.
/// - [topUp]             — credit funds via a payment provider.
/// - [applyPromo]        — redeem a promo code for wallet credit.
///
/// The abstract interface makes the implementation swappable in tests and
/// keeps the presentation layer free of any HTTP concerns.
abstract class WalletRepository {
  /// Returns the current wallet balance in the smallest currency unit.
  Future<int> getBalance();

  /// Returns the most recent transactions, newest first.
  Future<List<TransactionModel>> getTransactions({int limit = 50});

  /// Credits [amount] to the wallet via the given [provider].
  ///
  /// [provider] is one of `click`, `payme` or `prepaid`. Returns the new
  /// balance after the top-up has been applied.
  Future<int> topUp(int amount, {String provider = 'click'});

  /// Redeems [code] for wallet credit.
  ///
  /// Returns the bonus amount granted (in the smallest currency unit).
  Future<int> applyPromo(String code);
}

/// Concrete [WalletRepository] backed by the Virent [ApiClient].
///
/// Talks to the `/wallet/*` endpoints exposed by the embedded shelf server
/// (desktop) or the desktop PC's IP (mobile). The repository is resilient to
/// the small payload differences between the legacy Node backend and the
/// embedded server — it inspects both `balance` and `data.balance` keys and
/// gracefully coerces numeric strings.
class WalletRepositoryImpl implements WalletRepository {
  final ApiClient _api;

  /// Creates a repository wrapping [api] (or a fresh [ApiClient] when omitted).
  WalletRepositoryImpl([ApiClient? api]) : _api = api ?? ApiClient();

  @override
  Future<int> getBalance() async {
    final data = await _api.get('/wallet');
    final raw = data['balance'] ??
        (data['data'] is Map<String, dynamic>
            ? (data['data'] as Map<String, dynamic>)['balance']
            : null) ??
        0;
    return _coerceInt(raw);
  }

  @override
  Future<List<TransactionModel>> getTransactions({int limit = 50}) async {
    final data = await _api.get('/wallet/transactions?limit=$limit');
    final list = (data['transactions'] ??
            data['data'] ??
            const <dynamic>[]) as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map(TransactionModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<int> topUp(int amount, {String provider = 'click'}) async {
    if (amount <= 0) {
      throw const ApiException('Top-up amount must be greater than zero');
    }
    final data = await _api.post('/wallet/topup', {
      'amount': amount,
      'provider': provider,
    });
    final raw = data['balance'] ??
        data['new_balance'] ??
        (data['data'] is Map<String, dynamic>
            ? (data['data'] as Map<String, dynamic>)['balance']
            : null) ??
        0;
    return _coerceInt(raw);
  }

  @override
  Future<int> applyPromo(String code) async {
    if (code.isEmpty) {
      throw const ApiException('Promo code cannot be empty');
    }
    final data = await _api.post('/wallet/promo', {'code': code.toUpperCase()});
    final granted = data['granted'] ??
        data['bonus'] ??
        data['amount'] ??
        (data['data'] is Map<String, dynamic>
            ? (data['data'] as Map<String, dynamic>)['granted']
            : null) ??
        0;
    return _coerceInt(granted);
  }

  // ---- Helpers ---------------------------------------------------------------

  static int _coerceInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
