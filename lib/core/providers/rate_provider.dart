import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/currency_rates.dart';
import '../services/rate_service.dart';
import '../utils/constants.dart';

// ─────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────
enum RateFetchStatus { idle, loading, success, error, offline }

class RateState {
  const RateState({
    required this.rates,
    required this.status,
    this.errorMessage,
  });

  final CurrencyRates rates;
  final RateFetchStatus status;
  final String? errorMessage;

  bool get isLoading  => status == RateFetchStatus.loading;
  bool get isError    => status == RateFetchStatus.error;
  bool get isOffline  => status == RateFetchStatus.offline;
  bool get isStale    => rates.isStale;
  bool get hasRates   => !rates.isEmpty;

  RateState copyWith({
    CurrencyRates? rates,
    RateFetchStatus? status,
    String? errorMessage,
  }) {
    return RateState(
      rates: rates ?? this.rates,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

// ─────────────────────────────────────────────
//  Notifier
// ─────────────────────────────────────────────
class RateNotifier extends AsyncNotifier<RateState> {
  @override
  Future<RateState> build() async {
    // Initialise the service (loads cache + triggers background fetch)
    final rates = await RateService.instance.init();

    return RateState(
      rates: rates,
      status: rates.isEmpty
          ? RateFetchStatus.offline
          : RateFetchStatus.success,
    );
  }

  // ── Public actions ───────────────────────────

  /// Forces an immediate network refresh.
  Future<void> forceRefresh() async {
    state = AsyncData(
      state.valueOrNull?.copyWith(status: RateFetchStatus.loading) ??
          RateState(
            rates: CurrencyRates.empty,
            status: RateFetchStatus.loading,
          ),
    );

    try {
      final rates = await RateService.instance.forceRefresh();
      state = AsyncData(
        RateState(rates: rates, status: RateFetchStatus.success),
      );
    } catch (e) {
      final cached = await RateService.instance.getCachedRates();
      state = AsyncData(
        RateState(
          rates: cached,
          status: cached.isEmpty
              ? RateFetchStatus.offline
              : RateFetchStatus.error,
          errorMessage: 'No se pudo actualizar. Usando tasas guardadas.',
        ),
      );
    }
  }

  /// Applies a manual rate override for a specific pair.
  void setManualOverride(String pair, double rate) {
    RateService.instance.setManualOverride(pair, rate);
    final updated = RateService.instance.current;
    state = AsyncData(
      RateState(rates: updated, status: RateFetchStatus.success),
    );
  }

  void clearManualOverride(String pair) {
    RateService.instance.clearManualOverride(pair);
    final updated = RateService.instance.current;
    state = AsyncData(
      RateState(rates: updated, status: RateFetchStatus.success),
    );
  }

  void clearAllManualOverrides() {
    RateService.instance.clearAllManualOverrides();
    final updated = RateService.instance.current;
    state = AsyncData(
      RateState(rates: updated, status: RateFetchStatus.success),
    );
  }

  bool hasManualOverride(String pair) =>
      RateService.instance.hasManualOverride(pair);

  double? getManualOverride(String pair) =>
      RateService.instance.getManualOverride(pair);
}

// ─────────────────────────────────────────────
//  Providers
// ─────────────────────────────────────────────

/// Main provider — exposes [AsyncValue<RateState>].
final rateProvider = AsyncNotifierProvider<RateNotifier, RateState>(
  RateNotifier.new,
);

/// Convenience selector: just the [CurrencyRates] object.
/// Falls back to [CurrencyRates.empty] while loading.
final currencyRatesProvider = Provider<CurrencyRates>((ref) {
  return ref.watch(rateProvider).valueOrNull?.rates ?? CurrencyRates.empty;
});

/// True while a fetch is in progress.
final ratesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(rateProvider).valueOrNull?.isLoading ?? false;
});

/// True if we have no network and no cached rates.
final ratesOfflineProvider = Provider<bool>((ref) {
  return ref.watch(rateProvider).valueOrNull?.isOffline ?? false;
});

/// True if current rates are older than [kRateRefreshInterval].
final ratesStaleProvider = Provider<bool>((ref) {
  return ref.watch(rateProvider).valueOrNull?.isStale ?? false;
});

/// "hace X min" string for UI indicators.
final ratesLastUpdatedProvider = Provider<String>((ref) {
  final rates = ref.watch(currencyRatesProvider);
  if (rates.isEmpty) return 'Sin datos';
  final mins = rates.minutesAgo;
  if (mins < 1) return 'ahora mismo';
  if (mins < 60) return 'hace $mins min';
  final hrs = (mins / 60).floor();
  return 'hace $hrs h';
});

/// Error message if last fetch failed (but cached rates are available).
final ratesErrorMessageProvider = Provider<String?>((ref) {
  return ref.watch(rateProvider).valueOrNull?.errorMessage;
});

/// BCV rate as a double (0 if unavailable).
final bcvRateProvider = Provider<double>((ref) {
  return ref.watch(currencyRatesProvider).bcvRate;
});

/// Parallel rate as a double (0 if unavailable).
final parallelRateProvider = Provider<double>((ref) {
  return ref.watch(currencyRatesProvider).parallelRate;
});

/// Crypto rates map.
final cryptoRatesProvider = Provider<Map<String, double>>((ref) {
  final rates = ref.watch(currencyRatesProvider);
  return {
    CurrencyCodes.btc: rates.btcUsd,
    CurrencyCodes.eth: rates.ethUsd,
    CurrencyCodes.sol: rates.solUsd,
  };
});
