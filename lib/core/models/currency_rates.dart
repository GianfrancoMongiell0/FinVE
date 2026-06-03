// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import '../utils/constants.dart';

/// Aggregated snapshot of all supported exchange rates at a point in time.
/// All rates are expressed as: 1 USD = X [currency].
class CurrencyRates {
  const CurrencyRates({
    required this.bcvRate,
    required this.parallelRate,
    required this.btcUsd,
    required this.ethUsd,
    required this.solUsd,
    required this.fetchedAt,
    this.isManualOverride = false,
    this.isCached = false,
  });

  /// How many VES you get for 1 USD (BCV official rate).
  final double bcvRate;

  /// How many VES you get for 1 USD (parallel / black market rate).
  final double parallelRate;

  /// USD price of 1 BTC.
  final double btcUsd;

  /// USD price of 1 ETH.
  final double ethUsd;

  /// USD price of 1 SOL.
  final double solUsd;

  /// When this snapshot was last fetched from the network.
  final DateTime fetchedAt;

  /// True when the user has manually set one or more rates.
  final bool isManualOverride;

  /// True when rates come from cache (not fresh from network).
  final bool isCached;

  // ─────────────────────────────────────────────
  //  Fallback / empty snapshot
  // ─────────────────────────────────────────────
  static final CurrencyRates empty = CurrencyRates(
    bcvRate: 0,
    parallelRate: 0,
    btcUsd: 0,
    ethUsd: 0,
    solUsd: 0,
    fetchedAt: DateTime.fromMillisecondsSinceEpoch(0),
    isCached: true,
  );

  bool get isEmpty =>
      bcvRate == 0 && parallelRate == 0 && btcUsd == 0;

  // ─────────────────────────────────────────────
  //  fromMap / toMap (for caching in memory/prefs)
  // ─────────────────────────────────────────────
  factory CurrencyRates.fromMap(Map<String, dynamic> map) {
    return CurrencyRates(
      bcvRate: (map['bcv_rate'] as num?)?.toDouble() ?? 0,
      parallelRate: (map['parallel_rate'] as num?)?.toDouble() ?? 0,
      btcUsd: (map['btc_usd'] as num?)?.toDouble() ?? 0,
      ethUsd: (map['eth_usd'] as num?)?.toDouble() ?? 0,
      solUsd: (map['sol_usd'] as num?)?.toDouble() ?? 0,
      fetchedAt: map['fetched_at'] != null
          ? DateTime.parse(map['fetched_at'] as String)
          : DateTime.now(),
      isManualOverride: (map['is_manual_override'] as bool?) ?? false,
      isCached: (map['is_cached'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bcv_rate': bcvRate,
      'parallel_rate': parallelRate,
      'btc_usd': btcUsd,
      'eth_usd': ethUsd,
      'sol_usd': solUsd,
      'fetched_at': fetchedAt.toIso8601String(),
      'is_manual_override': isManualOverride,
      'is_cached': isCached,
    };
  }

  // ─────────────────────────────────────────────
  //  copyWith
  // ─────────────────────────────────────────────
  CurrencyRates copyWith({
    double? bcvRate,
    double? parallelRate,
    double? btcUsd,
    double? ethUsd,
    double? solUsd,
    DateTime? fetchedAt,
    bool? isManualOverride,
    bool? isCached,
  }) {
    return CurrencyRates(
      bcvRate: bcvRate ?? this.bcvRate,
      parallelRate: parallelRate ?? this.parallelRate,
      btcUsd: btcUsd ?? this.btcUsd,
      ethUsd: ethUsd ?? this.ethUsd,
      solUsd: solUsd ?? this.solUsd,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      isManualOverride: isManualOverride ?? this.isManualOverride,
      isCached: isCached ?? this.isCached,
    );
  }

  // ─────────────────────────────────────────────
  //  Conversion helpers
  // ─────────────────────────────────────────────

  /// Converts [amount] in [fromCurrency] to USD.
  /// Returns null if the rate is unavailable (zero).
  double? toUsd(double amount, String fromCurrency) {
    if (amount == 0) return 0;
    switch (fromCurrency.toUpperCase()) {
      case CurrencyCodes.usd:
        return amount;
      case CurrencyCodes.ves:
        if (bcvRate == 0) return null;
        return amount / bcvRate;
      case CurrencyCodes.btc:
        if (btcUsd == 0) return null;
        return amount * btcUsd;
      case CurrencyCodes.eth:
        if (ethUsd == 0) return null;
        return amount * ethUsd;
      case CurrencyCodes.sol:
        if (solUsd == 0) return null;
        return amount * solUsd;
      default:
        return null;
    }
  }

  /// Converts [amountUsd] from USD to [toCurrency].
  double? fromUsd(double amountUsd, String toCurrency) {
    if (amountUsd == 0) return 0;
    switch (toCurrency.toUpperCase()) {
      case CurrencyCodes.usd:
        return amountUsd;
      case CurrencyCodes.ves:
        if (bcvRate == 0) return null;
        return amountUsd * bcvRate;
      case CurrencyCodes.btc:
        if (btcUsd == 0) return null;
        return amountUsd / btcUsd;
      case CurrencyCodes.eth:
        if (ethUsd == 0) return null;
        return amountUsd / ethUsd;
      case CurrencyCodes.sol:
        if (solUsd == 0) return null;
        return amountUsd / solUsd;
      default:
        return null;
    }
  }

  /// Converts [amount] in [fromCurrency] to [toCurrency].
  double? convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    final usd = toUsd(amount, fromCurrency);
    if (usd == null) return null;
    return fromUsd(usd, toCurrency);
  }

  /// Converts [amount] in [fromCurrency] to VES using the parallel rate.
  double? toVesParallel(double amount, String fromCurrency) {
    if (parallelRate == 0) return null;
    final usd = toUsd(amount, fromCurrency);
    if (usd == null) return null;
    return usd * parallelRate;
  }

  // ─────────────────────────────────────────────
  //  Staleness
  // ─────────────────────────────────────────────
  bool get isStale =>
      DateTime.now().difference(fetchedAt) > const Duration(minutes: 30);

  int get minutesAgo => DateTime.now().difference(fetchedAt).inMinutes;

  @override
  String toString() =>
      'CurrencyRates(BCV: $bcvRate, Parallel: $parallelRate, '
      'BTC: \$$btcUsd, ETH: \$$ethUsd, SOL: \$$solUsd, '
      'cached: $isCached, stale: $isStale)';
}
