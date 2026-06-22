/// Tariff model — represents a Virent rental tariff option.
///
/// Virent offers three standard tariffs that the rider can pick before
/// starting a ride:
///
/// * **Per-minute** — pay-as-you-go at [pricePerMin].
/// * **30-min package** — flat [basePrice] for up to 30 minutes.
/// * **1-hour package** — flat [basePrice] for up to 60 minutes.
///
/// The booking modal uses [Tariff.compareWith] to render a side-by-side
/// price breakdown so the rider can pick the cheapest option for their
/// expected ride duration.
class Tariff {
  /// Server-side tariff identifier (e.g. `'per-minute'`, `'package-30'`).
  final String id;

  /// Human readable name shown in the tariff selector.
  final String name;

  /// Per-minute rate in UZS. Always set for per-minute tariffs; `0` for
  /// packages (the cost is captured by [basePrice] instead).
  final int pricePerMin;

  /// Flat base price in UZS. `0` for per-minute tariffs.
  final int basePrice;

  /// Maximum number of minutes covered by [basePrice] before overage
  /// applies. Defaults to `null` for per-minute tariffs (no cap).
  final int? includedMinutes;

  /// Short description shown under the tariff name in the comparison.
  final String description;

  /// `true` when this tariff charges per minute rather than a flat fee.
  final bool isPerMinute;

  /// Creates a [Tariff].
  const Tariff({
    required this.id,
    required this.name,
    required this.pricePerMin,
    required this.basePrice,
    this.includedMinutes,
    required this.description,
    required this.isPerMinute,
  });

  /// Per-minute tariff (pay-as-you-go).
  static const Tariff perMinute = Tariff(
    id: 'per-minute',
    name: 'Per-minute',
    pricePerMin: 200,
    basePrice: 0,
    includedMinutes: null,
    description: 'Pay only for the minutes you ride.',
    isPerMinute: true,
  );

  /// 30-minute package — flat fee for up to 30 minutes.
  static const Tariff package30 = Tariff(
    id: 'package-30',
    name: '30-min package',
    pricePerMin: 0,
    basePrice: 5000,
    includedMinutes: 30,
    description: 'Best for short commutes up to 30 minutes.',
    isPerMinute: false,
  );

  /// 1-hour package — flat fee for up to 60 minutes.
  static const Tariff package60 = Tariff(
    id: 'package-60',
    name: '1-hour package',
    pricePerMin: 0,
    basePrice: 9000,
    includedMinutes: 60,
    description: 'Save 10% on rides up to 1 hour.',
    isPerMinute: false,
  );

  /// Canonical list of every tariff Virent currently offers, in the order
  /// they should appear in the booking modal.
  static const List<Tariff> catalogue = <Tariff>[
    perMinute,
    package30,
    package60,
  ];

  /// Parses a JSON object into a [Tariff].
  ///
  /// Resilient to missing fields — defaults are substituted so a partial
  /// payload never crashes the UI.
  factory Tariff.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['tariff_id'] ?? '').toString();
    final isPerMinute = id.contains('per-minute') ||
        (json['is_per_minute'] ?? json['isPerMinute'] ?? false) == true;
    return Tariff(
      id: id,
      name: (json['name'] ?? json['label'] ?? 'Tariff').toString(),
      pricePerMin: _coerceInt(json['price_per_min'] ?? json['pricePerMin']),
      basePrice: _coerceInt(json['base_price'] ?? json['basePrice']),
      includedMinutes: json['included_minutes'] == null
          ? null
          : _coerceInt(json['included_minutes'] ?? json['includedMinutes']),
      description:
          (json['description'] ?? json['summary'] ?? '').toString(),
      isPerMinute: isPerMinute,
    );
  }

  /// Serialises the tariff back to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'price_per_min': pricePerMin,
        'base_price': basePrice,
        if (includedMinutes != null) 'included_minutes': includedMinutes,
        'description': description,
        'is_per_minute': isPerMinute,
      };

  /// Computes the total cost (in UZS) for a ride of [minutes] minutes under
  /// this tariff.
  ///
  /// For per-minute tariffs the result is simply `minutes * pricePerMin`.
  /// For packages the base price covers [includedMinutes]; any extra minutes
  /// are charged at the overage rate (here approximated as 200 UZS/min).
  int costForMinutes(int minutes) {
    if (minutes <= 0) return 0;
    if (isPerMinute) return minutes * pricePerMin;
    final cap = includedMinutes ?? 0;
    if (minutes <= cap) return basePrice;
    const int overagePerMin = 200;
    return basePrice + (minutes - cap) * overagePerMin;
  }

  /// Returns the savings (in UZS) of choosing this tariff over [other] for a
  /// ride of [minutes] minutes. A positive value means this tariff is
  /// cheaper than [other]; a negative value means it is more expensive.
  int savingsVersus(Tariff other, int minutes) {
    return other.costForMinutes(minutes) - costForMinutes(minutes);
  }

  /// Returns a copy of this tariff with the supplied fields replaced.
  Tariff copyWith({
    String? id,
    String? name,
    int? pricePerMin,
    int? basePrice,
    int? includedMinutes,
    String? description,
    bool? isPerMinute,
  }) {
    return Tariff(
      id: id ?? this.id,
      name: name ?? this.name,
      pricePerMin: pricePerMin ?? this.pricePerMin,
      basePrice: basePrice ?? this.basePrice,
      includedMinutes: includedMinutes ?? this.includedMinutes,
      description: description ?? this.description,
      isPerMinute: isPerMinute ?? this.isPerMinute,
    );
  }

  /// Builds a side-by-side comparison row for this tariff against [other]
  /// for the supplied [minutes]. Useful for the booking modal's tariff
  /// selector — callers can render the returned breakdown verbatim.
  TariffComparison compareWith(Tariff other, int minutes) {
    return TariffComparison(
      left: this,
      right: other,
      minutes: minutes,
      leftCost: costForMinutes(minutes),
      rightCost: other.costForMinutes(minutes),
    );
  }

  @override
  String toString() => 'Tariff(id: $id, name: $name, '
      'perMin: $pricePerMin, base: $basePrice)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tariff && other.id == id && other.name == name);

  @override
  int get hashCode => Object.hash(id, name);

  static int _coerceInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Side-by-side breakdown of two tariffs for a fixed ride duration.
///
/// Returned by [Tariff.compareWith] and rendered by the booking modal to
/// help the rider choose the cheaper option.
class TariffComparison {
  /// Creates a [TariffComparison].
  const TariffComparison({
    required this.left,
    required this.right,
    required this.minutes,
    required this.leftCost,
    required this.rightCost,
  });

  /// First tariff (usually the per-minute one).
  final Tariff left;

  /// Second tariff (usually a package).
  final Tariff right;

  /// Ride duration in minutes the comparison is based on.
  final int minutes;

  /// Total cost under [left] for [minutes] minutes.
  final int leftCost;

  /// Total cost under [right] for [minutes] minutes.
  final int rightCost;

  /// The cheaper of the two tariffs, or `null` when they tie.
  Tariff? get cheaper {
    if (leftCost == rightCost) return null;
    return leftCost < rightCost ? left : right;
  }

  /// Savings achieved by picking [cheaper] instead of the more expensive
  /// tariff. Always `>= 0`.
  int get savings => (leftCost - rightCost).abs();
}
