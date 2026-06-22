import '../../../../core/configs/services/api_client.dart';
import '../../../../core/error/api_exceptions.dart';
import '../models/promo_code_model.dart';

/// Contract for the payment data layer.
///
/// The payment feature only needs two operations:
/// - [validatePromo]   — confirm a promo code is still redeemable for a ride
///   of [total] and return the parsed [PromoCodeModel].
/// - [processPayment]  — settle a completed ride via one of the supported
///   payment rails (`wallet`, `click`, `payme`, `prepaid`).
abstract class PaymentRepository {
  /// Validates [code] against a ride totalling [total] (in UZS).
  ///
  /// Returns the parsed promo code with the server-confirmed `isValid` flag.
  Future<PromoCodeModel> validatePromo(String code, double total);

  /// Settles the ride identified by [rideId] using the given [method].
  ///
  /// [method] is one of `wallet`, `click`, `payme` or `prepaid`. When
  /// [promoCode] is non-empty it is forwarded to the backend so the discount
  /// is applied server-side. Returns the final amount the user was charged
  /// (after the discount), in the smallest currency unit.
  Future<int> processPayment({
    required String rideId,
    required String method,
    double total = 0,
    String promoCode = '',
  });
}

/// Concrete [PaymentRepository] backed by the Virent [ApiClient].
class PaymentRepositoryImpl implements PaymentRepository {
  final ApiClient _api;

  /// Creates a repository wrapping [api] (or a fresh [ApiClient] when omitted).
  PaymentRepositoryImpl([ApiClient? api]) : _api = api ?? ApiClient();

  @override
  Future<PromoCodeModel> validatePromo(String code, double total) async {
    if (code.isEmpty) {
      throw const ApiException('Promo code cannot be empty');
    }
    final data = await _api.post('/promos/validate', {
      'code': code.toUpperCase(),
      'total': total,
    });
    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;
    return PromoCodeModel.fromJson(payload);
  }

  @override
  Future<int> processPayment({
    required String rideId,
    required String method,
    double total = 0,
    String promoCode = '',
  }) async {
    if (rideId.isEmpty) {
      throw const ApiException('rideId is required to process payment');
    }
    final body = <String, dynamic>{
      'ride_id': rideId,
      'method': method,
      'total': total,
    };
    if (promoCode.isNotEmpty) body['promo_code'] = promoCode.toUpperCase();

    final data = await _api.post('/payments/process', body);
    final charged = data['charged'] ??
        data['amount'] ??
        data['total'] ??
        (data['data'] is Map<String, dynamic>
            ? (data['data'] as Map<String, dynamic>)['charged']
            : null) ??
        0;
    return _coerceInt(charged);
  }

  static int _coerceInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
