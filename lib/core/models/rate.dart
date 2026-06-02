class Rate {
  const Rate({
    this.id,
    required this.currencyPair,
    required this.rate,
    required this.fetchedAt,
  });

  final int? id;
  final String currencyPair;
  final double rate;
  final DateTime fetchedAt;

  // ─────────────────────────────────────────────
  //  Serialisation
  // ─────────────────────────────────────────────
  factory Rate.fromMap(Map<String, dynamic> map) {
    return Rate(
      id: map['id'] as int?,
      currencyPair: map['currency_pair'] as String,
      rate: (map['rate'] as num).toDouble(),
      fetchedAt: DateTime.parse(map['fetched_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'currency_pair': currencyPair,
      'rate': rate,
      'fetched_at': fetchedAt.toIso8601String(),
    };
  }

  // ─────────────────────────────────────────────
  //  copyWith
  // ─────────────────────────────────────────────
  Rate copyWith({
    int? id,
    String? currencyPair,
    double? rate,
    DateTime? fetchedAt,
  }) {
    return Rate(
      id: id ?? this.id,
      currencyPair: currencyPair ?? this.currencyPair,
      rate: rate ?? this.rate,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  // ─────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────

  /// True if older than [maxAge].
  bool isStale({Duration maxAge = const Duration(minutes: 30)}) {
    return DateTime.now().difference(fetchedAt) > maxAge;
  }

  /// Minutes since last fetch.
  int get minutesAgo => DateTime.now().difference(fetchedAt).inMinutes;

  @override
  String toString() =>
      'Rate($currencyPair: $rate @ $fetchedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rate &&
          runtimeType == other.runtimeType &&
          currencyPair == other.currencyPair;

  @override
  int get hashCode => currencyPair.hashCode;
}
