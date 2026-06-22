/// Payment-card model — represents a saved bank card in the rider's wallet.
///
/// Mirrors the JSON shape returned by the `/wallet/cards` endpoint:
///
/// ```json
/// {
///   "id": "card_42",
///   "brand": "visa",
///   "last4": "4242",
///   "expiry_month": 12,
///   "expiry_year": 27,
///   "cardholder": "JANE DOE",
///   "is_default": true
/// }
/// ```
///
/// The model is intentionally framework-free so it can be unit-tested in
/// isolation and reused by both the wallet and payment features.
///

/// Supported card brands. Each brand carries the asset-less colour and
/// Material icon used by the wallet UI — no SVG/PNG assets required.
enum CardBrand {
  /// Visa — international.
  visa,

  /// Mastercard — international.
  mastercard,

  /// MIR — Russian national card system.
  mir,

  /// Uzcard — Uzbek national card system.
  uzcard,

  /// Humo — Uzbek national card system (alternative to Uzcard).
  humo,

  /// Unknown / generic card.
  unknown,
}

/// Extension adding presentation helpers to [CardBrand].
extension CardBrandX on CardBrand {
  /// Short display label (e.g. `'VISA'`, `'Mastercard'`).
  String get label {
    switch (this) {
      case CardBrand.visa:
        return 'VISA';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.mir:
        return 'MIR';
      case CardBrand.uzcard:
        return 'Uzcard';
      case CardBrand.humo:
        return 'Humo';
      case CardBrand.unknown:
        return 'CARD';
    }
  }

  /// Brand accent colour used for the card chip and logo background.
  int get colorValue {
    switch (this) {
      case CardBrand.visa:
        return 0xFF1A1F71; // Visa blue
      case CardBrand.mastercard:
        return 0xFFEB001B; // Mastercard red
      case CardBrand.mir:
        return 0xFF0F754E; // MIR green
      case CardBrand.uzcard:
        return 0xFF0089D0; // Uzcard blue
      case CardBrand.humo:
        return 0xFF6E2B8E; // Humo purple
      case CardBrand.unknown:
        return 0xFF4B5563; // neutral grey
    }
  }
}

/// A saved payment card.
class PaymentCard {
  /// Creates a [PaymentCard].
  const PaymentCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardholder,
    required this.isDefault,
  });

  /// Server-assigned card identifier (e.g. `'card_42'`).
  final String id;

  /// Card brand — drives the colour and logo glyph.
  final CardBrand brand;

  /// Last four digits of the PAN.
  final String last4;

  /// Expiry month (1–12).
  final int expiryMonth;

  /// Expiry year (2-digit, e.g. `27` for 2027).
  final int expiryYear;

  /// Cardholder name in upper case, as printed on the card.
  final String cardholder;

  /// `true` when this is the default card used for one-tap payments.
  final bool isDefault;

  /// Masked PAN suitable for display, e.g. `•••• 4242`.
  String get maskedNumber => '•••• $last4';

  /// Masked PAN with the brand prefix, e.g. `VISA •••• 4242`.
  String get maskedWithBrand => '${brand.label} $maskedNumber';

  /// Formatted expiry string, e.g. `12/27`.
  String get expiry => '${expiryMonth.toString().padLeft(2, '0')}/'
      '${expiryYear.toString().padLeft(2, '0')}';

  /// Parses a JSON object into a [PaymentCard].
  factory PaymentCard.fromJson(Map<String, dynamic> json) {
    return PaymentCard(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      brand: _parseBrand(json['brand'] ?? json['system']),
      last4: (json['last4'] ?? json['last_four'] ?? '0000').toString(),
      expiryMonth: _coerceInt(json['expiry_month'] ?? json['expiryMonth']),
      expiryYear: _coerceInt(json['expiry_year'] ?? json['expiryYear']),
      cardholder: (json['cardholder'] ?? json['holder_name'] ?? '').toString(),
      isDefault: (json['is_default'] ?? json['isDefault'] ?? false) as bool,
    );
  }

  /// Serialises the card back to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'brand': brand.name,
        'last4': last4,
        'expiry_month': expiryMonth,
        'expiry_year': expiryYear,
        'cardholder': cardholder,
        'is_default': isDefault,
      };

  /// Returns a copy with the supplied fields replaced.
  PaymentCard copyWith({
    String? id,
    CardBrand? brand,
    String? last4,
    int? expiryMonth,
    int? expiryYear,
    String? cardholder,
    bool? isDefault,
  }) {
    return PaymentCard(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cardholder: cardholder ?? this.cardholder,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() => 'PaymentCard($maskedWithBrand, default: $isDefault)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentCard && other.id == id);

  @override
  int get hashCode => id.hashCode;

  // ---- Helpers -------------------------------------------------------------

  static CardBrand _parseBrand(dynamic raw) {
    switch (raw?.toString().toLowerCase()) {
      case 'visa':
        return CardBrand.visa;
      case 'mastercard':
      case 'mc':
        return CardBrand.mastercard;
      case 'mir':
        return CardBrand.mir;
      case 'uzcard':
      case 'uz_card':
        return CardBrand.uzcard;
      case 'humo':
        return CardBrand.humo;
      default:
        return CardBrand.unknown;
    }
  }

  static int _coerceInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
