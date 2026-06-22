import '../../../../core/error/api_exceptions.dart';

/// Type of discount a promo code applies.
///
/// - [percent] — `discount` is a percentage (0–100) of the ride total.
/// - [fixed]   — `discount` is a flat amount in the smallest currency unit.
enum PromoType { percent, fixed }

/// Canonical representation of a promo code returned by the backend.
///
/// Ported from BarqScoot's `PromoCode` entity and extended with the Virent
/// specifics (`maxDiscount`, `minTripCost` and an explicit `isValid` flag the
/// server attaches when validating a code against a ride).
class PromoCodeModel {
  /// Server-issued identifier.
  final int id;

  /// The case-insensitive code the user types in.
  final String code;

  /// Discount kind — percentage or fixed amount.
  final PromoType type;

  /// Magnitude of the discount. For [PromoType.percent] this is a value
  /// between 0 and 100; for [PromoType.fixed] it is the smallest currency
  /// unit (tiyin / UZS).
  final double discount;

  /// Cap on the discount amount — applies to [PromoType.percent] only.
  final double maxDiscount;

  /// Minimum trip cost a ride must reach for the code to apply.
  final double minTripCost;

  /// ISO-8601 expiry timestamp.
  final DateTime expiryDate;

  /// `true` when the backend confirmed the code is still redeemable.
  final bool isValid;

  /// Human readable note returned by the backend (e.g. "20% off your next
  /// ride"). May be empty.
  final String description;

  /// Creates a [PromoCodeModel].
  const PromoCodeModel({
    required this.id,
    required this.code,
    required this.type,
    required this.discount,
    required this.maxDiscount,
    required this.minTripCost,
    required this.expiryDate,
    required this.isValid,
    this.description = '',
  });

  /// Parses a JSON payload into a [PromoCodeModel].
  ///
  /// Accepts both `snake_case` and `camelCase` keys and tolerates numeric
  /// fields encoded as strings. Throws [ApiException] when `code` is missing.
  factory PromoCodeModel.fromJson(Map<String, dynamic> json) {
    final code = (json['code'] ?? json['promo_code'] ?? '').toString();
    if (code.isEmpty) {
      throw const ApiException('Promo payload missing `code`');
    }

    final typeRaw = (json['type'] ?? 'percent').toString().toLowerCase();
    final type = typeRaw == 'fixed' || typeRaw == 'amount'
        ? PromoType.fixed
        : PromoType.percent;

    final expiryRaw = (json['expiry_date'] ??
            json['expiryDate'] ??
            DateTime.now().add(const Duration(days: 365)))
        .toString();

    return PromoCodeModel(
      id: _coerceInt(json['id'] ?? json['ID']),
      code: code,
      type: type,
      discount: _coerceDouble(json['discount'] ??
          json['discount_percent'] ??
          json['discount_amount'] ??
          0),
      maxDiscount: _coerceDouble(json['max_discount'] ?? json['maxDiscount']),
      minTripCost: _coerceDouble(json['min_trip_cost'] ?? json['minTripCost']),
      expiryDate: DateTime.tryParse(expiryRaw) ??
          DateTime.now().add(const Duration(days: 365)),
      isValid: (json['is_valid'] ??
              json['isValid'] ??
              json['is_active'] ??
              json['isActive'] ??
              true) as bool,
      description: (json['description'] ?? json['message'] ?? '').toString(),
    );
  }

  /// Returns the discount amount for a ride of [total].
  ///
  /// For percentage codes the result is capped by [maxDiscount] and only
  /// applied when [total] is at least [minTripCost]. Returns `0` when the
  /// code is not [isValid] or the ride is too cheap.
  double discountFor(double total) {
    if (!isValid) return 0;
    if (total < minTripCost) return 0;
    if (type == PromoType.fixed) {
      return discount.clamp(0, total);
    }
    final raw = (total * discount) / 100;
    return maxDiscount > 0 ? raw.clamp(0, maxDiscount) : raw;
  }

  /// Serialises the model to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'type': type == PromoType.fixed ? 'fixed' : 'percent',
        'discount': discount,
        'max_discount': maxDiscount,
        'min_trip_cost': minTripCost,
        'expiry_date': expiryDate.toIso8601String(),
        'is_valid': isValid,
        'description': description,
      };

  @override
  String toString() =>
      'PromoCodeModel(code: $code, type: $type, discount: $discount, '
      'isValid: $isValid)';

  // ---- Helpers ---------------------------------------------------------------

  static int _coerceInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _coerceDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
