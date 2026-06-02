import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../database/daos/rate_cache_dao.dart';
import '../models/currency_rates.dart';
import '../utils/constants.dart';

class RateService {
  RateService._();
  static final RateService instance = RateService._();

  final RateCacheDao _dao = RateCacheDao.instance;

  // In-memory snapshot (avoids hitting SQLite on every conversion)
  CurrencyRates _cached = CurrencyRates.empty;
  CurrencyRates get current => _cached;

  // Manual overrides set by user in Settings
  final Map<String, double> _manualOverrides = {};

  Timer? _refreshTimer;

  // ─────────────────────────────────────────────
  //  Initialisation — call once on app launch
  // ─────────────────────────────────────────────
  Future<CurrencyRates> init() async {
    // Load whatever is in cache first (instant, offline-safe)
    _cached = await _loadFromCache();

    // Then try a fresh fetch in background
    fetchAllRates().catchError((e) {
      debugPrint('[RateService] Background fetch failed: $e');
    });

    // Schedule auto-refresh every 30 minutes
    _startRefreshTimer();

    return _cached;
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(kRateRefreshInterval, (_) {
      fetchAllRates().catchError((e) {
        debugPrint('[RateService] Periodic refresh failed: $e');
      });
    });
  }

  void dispose() {
    _refreshTimer?.cancel();
  }

  // ─────────────────────────────────────────────
  //  Main fetch — BCV + parallel + crypto
  // ─────────────────────────────────────────────
  Future<CurrencyRates> fetchAllRates() async {
    double? bcv, parallel, btc, eth, sol;

    // Run BCV, parallel and crypto concurrently
    final results = await Future.wait([
      _fetchBcvRate(),
      _fetchParallelRate(),
      _fetchCryptoRates(),
    ], eagerError: false);

    bcv      = results[0] as double?;
    parallel = results[1] as double?;
    final crypto = results[2] as Map<String, double>?;
    btc = crypto?[CurrencyCodes.btc];
    eth = crypto?[CurrencyCodes.eth];
    sol = crypto?[CurrencyCodes.sol];

    // Apply manual overrides where fresh data is unavailable
    bcv      ??= _manualOverrides[RatePairs.bcv]      ?? _cached.bcvRate;
    parallel ??= _manualOverrides[RatePairs.parallel] ?? _cached.parallelRate;
    btc      ??= _manualOverrides[RatePairs.btc]      ?? _cached.btcUsd;
    eth      ??= _manualOverrides[RatePairs.eth]      ?? _cached.ethUsd;
    sol      ??= _manualOverrides[RatePairs.sol]      ?? _cached.solUsd;

    final rates = CurrencyRates(
      bcvRate:      bcv,
      parallelRate: parallel,
      btcUsd:       btc,
      ethUsd:       eth,
      solUsd:       sol,
      fetchedAt:    DateTime.now(),
      isCached:     false,
      isManualOverride: _manualOverrides.isNotEmpty,
    );

    // Persist to SQLite cache
    await _persistToCache(rates);

    _cached = rates;
    debugPrint('[RateService] Rates refreshed: BCV=${rates.bcvRate}, '
        'BTC=\$${rates.btcUsd}');
    return rates;
  }

  // ─────────────────────────────────────────────
  //  Individual fetchers
  // ─────────────────────────────────────────────
  Future<double?> _fetchBcvRate() async {
    try {
      final response = await http
          .get(Uri.parse(ApiEndpoints.bcvRate))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final value = json['promedio'];
        return (value as num?)?.toDouble();
      }
    } catch (e) {
      debugPrint('[RateService] BCV fetch error: $e');
    }
    return null;
  }

  Future<double?> _fetchParallelRate() async {
    try {
      final response = await http
          .get(Uri.parse(ApiEndpoints.parallelRate))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final value = json['promedio'];
        return (value as num?)?.toDouble();
      }
    } catch (e) {
      debugPrint('[RateService] Parallel fetch error: $e');
    }
    return null;
  }

  Future<Map<String, double>?> _fetchCryptoRates() async {
    try {
      final response = await http
          .get(Uri.parse(ApiEndpoints.cryptoPrices))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          CurrencyCodes.btc:
              (json['bitcoin']?['usd'] as num?)?.toDouble() ?? 0,
          CurrencyCodes.eth:
              (json['ethereum']?['usd'] as num?)?.toDouble() ?? 0,
          CurrencyCodes.sol:
              (json['solana']?['usd'] as num?)?.toDouble() ?? 0,
        };
      }
    } catch (e) {
      debugPrint('[RateService] Crypto fetch error: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────
  //  Cache helpers
  // ─────────────────────────────────────────────
  Future<CurrencyRates> _loadFromCache() async {
    try {
      final rows = await _dao.getAll();
      if (rows.isEmpty) return CurrencyRates.empty;

      final rateMap = {for (final r in rows) r.currencyPair: r.rate};

      // Use the oldest fetched_at as the snapshot timestamp
      final fetchedAt = rows
          .map((r) => r.fetchedAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);

      return CurrencyRates(
        bcvRate:      rateMap[RatePairs.bcv]      ?? 0,
        parallelRate: rateMap[RatePairs.parallel] ?? 0,
        btcUsd:       rateMap[RatePairs.btc]      ?? 0,
        ethUsd:       rateMap[RatePairs.eth]      ?? 0,
        solUsd:       rateMap[RatePairs.sol]      ?? 0,
        fetchedAt:    fetchedAt,
        isCached:     true,
      );
    } catch (e) {
      debugPrint('[RateService] Cache load error: $e');
      return CurrencyRates.empty;
    }
  }

  Future<void> _persistToCache(CurrencyRates rates) async {
    await _dao.upsertAll({
      RatePairs.bcv:      rates.bcvRate,
      RatePairs.parallel: rates.parallelRate,
      RatePairs.btc:      rates.btcUsd,
      RatePairs.eth:      rates.ethUsd,
      RatePairs.sol:      rates.solUsd,
    });
  }

  // ─────────────────────────────────────────────
  //  Public helpers
  // ─────────────────────────────────────────────

  /// Returns the most recent rates (from memory, not a fresh fetch).
  Future<CurrencyRates> getCachedRates() async {
    if (!_cached.isEmpty) return _cached;
    _cached = await _loadFromCache();
    return _cached;
  }

  /// Forces an immediate refresh (e.g. pull-to-refresh).
  Future<CurrencyRates> forceRefresh() => fetchAllRates();

  /// Gets the BCV rate alone (from memory cache).
  double getBcvRate() => _cached.bcvRate;

  /// Gets the parallel rate alone (from memory cache).
  double getParallelRate() => _cached.parallelRate;

  /// Gets crypto rates as a map.
  Map<String, double> getCryptoRates() => {
        CurrencyCodes.btc: _cached.btcUsd,
        CurrencyCodes.eth: _cached.ethUsd,
        CurrencyCodes.sol: _cached.solUsd,
      };

  // ─────────────────────────────────────────────
  //  Manual override (Settings → offline mode)
  // ─────────────────────────────────────────────

  /// Sets a manual rate override for [pair].
  /// [pair] should be a [RatePairs] constant.
  void setManualOverride(String pair, double rate) {
    _manualOverrides[pair] = rate;

    // Apply immediately to in-memory snapshot
    _cached = _applyOverride(_cached, pair, rate);
    debugPrint('[RateService] Manual override set: $pair = $rate');
  }

  void clearManualOverride(String pair) {
    _manualOverrides.remove(pair);
  }

  void clearAllManualOverrides() {
    _manualOverrides.clear();
  }

  bool hasManualOverride(String pair) => _manualOverrides.containsKey(pair);
  double? getManualOverride(String pair) => _manualOverrides[pair];

  CurrencyRates _applyOverride(
      CurrencyRates rates, String pair, double rate) {
    return switch (pair) {
      RatePairs.bcv      => rates.copyWith(bcvRate: rate, isManualOverride: true),
      RatePairs.parallel => rates.copyWith(parallelRate: rate, isManualOverride: true),
      RatePairs.btc      => rates.copyWith(btcUsd: rate, isManualOverride: true),
      RatePairs.eth      => rates.copyWith(ethUsd: rate, isManualOverride: true),
      RatePairs.sol      => rates.copyWith(solUsd: rate, isManualOverride: true),
      _                  => rates,
    };
  }
}
