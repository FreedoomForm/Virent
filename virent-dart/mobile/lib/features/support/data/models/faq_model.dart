/// FAQ model — a single Frequently-Asked-Question entry plus the category
/// enum used to group entries in the UI.
///
/// The catalogue is pre-seeded with 15 common questions covering the five
/// categories Virent supports: rental, damage, tariffs, safety and account.
/// The data is bundled with the app (no network call required) so the FAQ
/// screen is always available — even offline.

/// Top-level FAQ categories shown as filter chips in the FAQ screen.
enum FAQCategory {
  /// Questions about unlocking, riding and ending a rental.
  rental,

  /// Questions about damage, theft and insurance.
  damage,

  /// Questions about pricing, promos and refunds.
  tariffs,

  /// Questions about helmets, traffic rules and emergencies.
  safety,

  /// Questions about login, OTP, profile and personal data.
  account,
}

/// Extension adding presentation helpers to [FAQCategory].
extension FAQCategoryX on FAQCategory {
  /// Human readable label shown on the filter chip.
  String get label {
    switch (this) {
      case FAQCategory.rental:
        return 'Rental';
      case FAQCategory.damage:
        return 'Damage';
      case FAQCategory.tariffs:
        return 'Tariffs';
      case FAQCategory.safety:
        return 'Safety';
      case FAQCategory.account:
        return 'Account';
    }
  }

  /// Material icon used alongside the label in the filter chip and the
  /// expandable card header.
  int get iconCodePoint {
    // Stored as code-point so the enum stays framework-free (no Flutter
    // dependency). Callers resolve via `IconData(codePoint, fontFamily:
    // 'MaterialIcons')` — see [faq_screen.dart].
    switch (this) {
      case FAQCategory.rental:
        return 0xe1d0; // Icons.electric_scooter
      case FAQCategory.damage:
        return 0xe10b; // Icons.build
      case FAQCategory.tariffs:
        return 0xe261; // Icons.payments
      case FAQCategory.safety:
        return 0xe1ce; // Icons.health_and_safety
      case FAQCategory.account:
        return 0xe1af; // Icons.person
    }
  }
}

/// A single FAQ entry.
class FAQItem {
  /// Creates a [FAQItem].
  const FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
  });

  /// Stable identifier used for `Hero` animations and `ListView` keys.
  final String id;

  /// The question, phrased as a rider would ask it.
  final String question;

  /// The answer, in plain text. Kept short so the expanded card stays
  /// scannable — agents link to the full help article when more detail is
  /// needed.
  final String answer;

  /// Category the question belongs to.
  final FAQCategory category;

  /// Pre-seeded catalogue of 15 common Virent FAQ entries, grouped by
  /// category. The order is the order they should appear in the FAQ screen
  /// when no filter is selected.
  static const List<FAQItem> catalogue = <FAQItem>[
    // ---- Rental -----------------------------------------------------------
    FAQItem(
      id: 'faq-001',
      category: FAQCategory.rental,
      question: 'How do I unlock a scooter?',
      answer: 'Tap a scooter marker on the map, then tap "Let\'s go". '
          'Alternatively, scan the QR code on the handlebar with the '
          'scanner button at the bottom of the home screen.',
    ),
    FAQItem(
      id: 'faq-002',
      category: FAQCategory.rental,
      question: 'Where can I park the scooter at the end of my ride?',
      answer: 'Park inside a green finish zone — they\'re outlined on the '
          'map. Ending a ride outside a finish zone incurs a 5,000 UZS '
          'relocation fee.',
    ),
    FAQItem(
      id: 'faq-003',
      category: FAQCategory.rental,
      question: 'Can I pause a ride and resume it later?',
      answer: 'Yes. Tap "Pause" on the active-ride screen — the scooter '
          'locks and the per-minute rate drops to 50 UZS/min while paused. '
          'Tap "Resume" to continue riding.',
    ),
    // ---- Damage -----------------------------------------------------------
    FAQItem(
      id: 'faq-004',
      category: FAQCategory.damage,
      question: 'What should I do if the scooter breaks down mid-ride?',
      answer: 'End the ride immediately and tap "Report a problem" on the '
          'receipt screen. Our team will refund the ride and dispatch a '
          'juicer to collect the scooter.',
    ),
    FAQItem(
      id: 'faq-005',
      category: FAQCategory.damage,
      question: 'Am I covered by insurance while riding?',
      answer: 'Every Virent scooter is covered by third-party liability '
          'insurance. Personal injury cover can be added per-ride from the '
          'booking modal for 1,000 UZS.',
    ),
    FAQItem(
      id: 'faq-006',
      category: FAQCategory.damage,
      question: 'What happens if I damage the scooter?',
      answer: 'Minor scratches are covered by Virent. Significant damage '
          '(bent frame, broken display) is charged at cost — you\'ll '
          'receive a quote before any payment is taken.',
    ),
    // ---- Tariffs ----------------------------------------------------------
    FAQItem(
      id: 'faq-007',
      category: FAQCategory.tariffs,
      question: 'How is the ride cost calculated?',
      answer: 'A base fare of 1,000 UZS plus 200 UZS per minute. The '
          '30-minute package (5,000 UZS) and 1-hour package (9,000 UZS) '
          'offer savings for longer rides.',
    ),
    FAQItem(
      id: 'faq-008',
      category: FAQCategory.tariffs,
      question: 'Can I use a promo code on top of a package?',
      answer: 'Yes — promo codes apply to the package price. Percentage '
          'promos are capped at 50% of the package cost.',
    ),
    FAQItem(
      id: 'faq-009',
      category: FAQCategory.tariffs,
      question: 'How do I get a refund for a cancelled ride?',
      answer: 'Cancellations within the first 60 seconds are free. After '
          'that the base fare is non-refundable; the per-minute portion is '
          'refunded to your wallet within 24 hours.',
    ),
    // ---- Safety -----------------------------------------------------------
    FAQItem(
      id: 'faq-010',
      category: FAQCategory.safety,
      question: 'Do I have to wear a helmet?',
      answer: 'Yes — helmets are mandatory by law. Each scooter has a '
          'helmet locked to the handlebar; unlock it with the same QR scan '
          'used to start the ride.',
    ),
    FAQItem(
      id: 'faq-011',
      category: FAQCategory.safety,
      question: 'Where am I allowed to ride?',
      answer: 'Cycle lanes and roads with a speed limit of 50 km/h or '
          'less. Riding on pavements, in parks and on motorways is '
          'prohibited and may result in a fine.',
    ),
    FAQItem(
      id: 'faq-012',
      category: FAQCategory.safety,
      question: 'What do I do in an emergency?',
      answer: 'Tap the red SOS button on the active-ride screen. This '
          'shares your live location with Virent support and the local '
          'emergency services (112).',
    ),
    // ---- Account ----------------------------------------------------------
    FAQItem(
      id: 'faq-013',
      category: FAQCategory.account,
      question: 'How do I log in without a phone number?',
      answer: 'Phone is the default, but you can also continue with '
          'Telegram from the auth screen — your Telegram identity is used '
          'to verify your account.',
    ),
    FAQItem(
      id: 'faq-014',
      category: FAQCategory.account,
      question: 'Can I have multiple payment cards on file?',
      answer: 'Yes — add as many cards as you like from the wallet. Mark '
          'one as the default to skip the picker on subsequent rides.',
    ),
    FAQItem(
      id: 'faq-015',
      category: FAQCategory.account,
      question: 'How do I delete my account and personal data?',
      answer: 'Open Settings → Account → Delete account. This wipes your '
          'profile, ride history and saved cards within 30 days, as '
          'required by GDPR.',
    ),
  ];

  /// Filters the [catalogue] by [category] (or returns the whole list when
  /// `null`).
  static List<FAQItem> forCategory(FAQCategory? category) {
    if (category == null) return catalogue;
    return catalogue.where((q) => q.category == category).toList();
  }

  /// Filters the [catalogue] by a free-text [query] — matches both the
  /// question and the answer, case-insensitive.
  static List<FAQItem> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return catalogue;
    return catalogue.where((item) {
      return item.question.toLowerCase().contains(q) ||
          item.answer.toLowerCase().contains(q);
    }).toList();
  }

  @override
  String toString() => 'FAQItem($id, $category, $question)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FAQItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
