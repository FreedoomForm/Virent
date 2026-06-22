import '../../../../core/error/api_exceptions.dart';

/// Direction of money movement for a wallet transaction.
///
/// - [credit]  increases the wallet balance (e.g. top-up, refund, promo grant).
/// - [debit]   decreases the wallet balance (e.g. ride fare, penalty).
/// - [other]   informational entries that do not affect the balance.
enum TransactionType { credit, debit, other }

/// Canonical representation of a single wallet ledger entry.
///
/// Ported from BarqScoot's `Transaction` entity and aligned with the Virent
/// embedded-server schema. The model is intentionally tolerant — [fromJson]
/// accepts both camelCase and snake_case keys and coerces numeric strings so
/// the UI does not crash when the backend returns slightly different payloads.
class TransactionModel {
  /// Server-issued identifier.
  final String id;

  /// Categorisation of the entry (`credit`, `debit`, `topup`, `ride`, etc.).
  final String type;

  /// Parsed direction of money movement.
  final TransactionType direction;

  /// Signed amount in the smallest currency unit (tiyin / UZS).
  ///
  /// Positive for credits, negative for debits. Use [absoluteAmount] when the
  /// sign is irrelevant (e.g. for display).
  final int amount;

  /// Human readable label shown in the transaction list.
  final String description;

  /// ISO-8601 timestamp string as returned by the backend.
  final String createdAt;

  /// Returns the absolute value of [amount].
  int get absoluteAmount => amount.abs();

  /// `true` when the transaction credits the wallet.
  bool get isCredit => direction == TransactionType.credit;

  /// `true` when the transaction debits the wallet.
  bool get isDebit => direction == TransactionType.debit;

  /// Creates a [TransactionModel].
  const TransactionModel({
    required this.id,
    required this.type,
    required this.direction,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  /// Parses a JSON payload into a [TransactionModel].
  ///
  /// Accepts both `snake_case` and `camelCase` keys and tolerates numeric
  /// amounts encoded as strings. Throws [ApiException] when `id` is missing.
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    if (id.isEmpty) {
      throw const ApiException('Transaction payload missing `id`');
    }

    final rawType = (json['type'] ?? json['kind'] ?? 'other').toString();
    final int amount = _coerceInt(json['amount']);

    return TransactionModel(
      id: id,
      type: rawType,
      direction: _parseDirection(rawType, amount),
      amount: amount,
      description: (json['description'] ?? json['note'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
    );
  }

  /// Serialises the model to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'description': description,
        'created_at': createdAt,
      };

  /// Returns a copy with the given fields overridden.
  TransactionModel copyWith({
    String? id,
    String? type,
    TransactionType? direction,
    int? amount,
    String? description,
    String? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'TransactionModel(id: $id, type: $type, amount: $amount, '
      'description: $description)';

  // ---- Helpers ---------------------------------------------------------------

  static int _coerceInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static TransactionType _parseDirection(String type, int amount) {
    final lower = type.toLowerCase();
    if (lower == 'credit' ||
        lower == 'topup' ||
        lower == 'top_up' ||
        lower == 'refund' ||
        lower == 'promo' ||
        lower == 'reward') {
      return TransactionType.credit;
    }
    if (lower == 'debit' ||
        lower == 'ride' ||
        lower == 'fare' ||
        lower == 'penalty' ||
        lower == 'charge') {
      return TransactionType.debit;
    }
    // Fall back to the sign of the amount when the type tag is ambiguous.
    if (amount > 0) return TransactionType.credit;
    if (amount < 0) return TransactionType.debit;
    return TransactionType.other;
  }
}
