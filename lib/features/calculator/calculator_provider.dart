import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/currency_rates.dart';
import '../../core/providers/rate_provider.dart';
import '../../core/utils/constants.dart';

// ─────────────────────────────────────────────
//  State: one editable field per currency
// ─────────────────────────────────────────────
class CalculatorState {
  const CalculatorState({
    required this.values,
    required this.lastEditedField,
    required this.rates,
  });

  /// Map of currencyCode → current display value (null = blank).
  final Map<String, double?> values;

  /// Which field the user last typed in.
  final String? lastEditedField;

  final CurrencyRates rates;

  /// Returns display string for a given currency field.
  String displayFor(String currency) {
    final v = values[currency];
    if (v == null) return '';
    if (currency == CurrencyCodes.btc ||
        currency == CurrencyCodes.eth ||
        currency == CurrencyCodes.sol) {
      // 8 significant decimal places for crypto
      return v == 0 ? '0' : _trimZeros(v.toStringAsFixed(8));
    }
    return v == 0 ? '0' : _trimZeros(v.toStringAsFixed(2));
  }

  static String _trimZeros(String s) {
    if (!s.contains('.')) return s;
    s = s.replaceAll(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }

  CalculatorState copyWith({
    Map<String, double?>? values,
    String? lastEditedField,
    CurrencyRates? rates,
  }) {
    return CalculatorState(
      values: values ?? this.values,
      lastEditedField: lastEditedField ?? this.lastEditedField,
      rates: rates ?? this.rates,
    );
  }

  static CalculatorState initial(CurrencyRates rates) => CalculatorState(
        values: {for (final c in _allFields) c: null},
        lastEditedField: null,
        rates: rates,
      );

  /// All 6 currency fields in display order.
  static const _allFields = [
    CurrencyCodes.usd,
    'VES_BCV',
    'VES_PARALLEL',
    CurrencyCodes.btc,
    CurrencyCodes.eth,
    CurrencyCodes.sol,
  ];

  static List<String> get allFields => _allFields;
}

// ─────────────────────────────────────────────
//  Notifier
// ─────────────────────────────────────────────
class CalculatorNotifier extends Notifier<CalculatorState> {
  @override
  CalculatorState build() {
    final rates = ref.watch(currencyRatesProvider);
    return CalculatorState.initial(rates);
  }

  /// Called whenever the user changes the value of [field].
  void onFieldChanged(String field, String raw) {
    final rates = state.rates;
    final parsed = double.tryParse(raw.replaceAll(',', '.'));

    if (parsed == null || raw.isEmpty) {
      // User cleared the field → clear all
      state = CalculatorState.initial(rates);
      return;
    }

    // Convert parsed value to USD first, then fan out to all fields
    final usd = _toUsd(parsed, field, rates);

    if (usd == null) {
      // Rate unavailable for this field — just update that field alone
      state = state.copyWith(
        values: {...state.values, field: parsed},
        lastEditedField: field,
      );
      return;
    }

    final newValues = <String, double?>{};
    for (final f in CalculatorState.allFields) {
      newValues[f] = _fromUsd(usd, f, rates);
    }
    // Keep the exact value the user typed (avoid floating-point drift)
    newValues[field] = parsed;

    state = CalculatorState(
      values: newValues,
      lastEditedField: field,
      rates: rates,
    );
  }

  void clear() {
    state = CalculatorState.initial(state.rates);
  }

  // ── Conversion helpers ───────────────────────

  double? _toUsd(double amount, String field, CurrencyRates rates) {
    return switch (field) {
      CurrencyCodes.usd => amount,
      'VES_BCV' => rates.bcvRate > 0 ? amount / rates.bcvRate : null,
      'VES_PARALLEL' =>
        rates.parallelRate > 0 ? amount / rates.parallelRate : null,
      CurrencyCodes.btc => rates.btcUsd > 0 ? amount * rates.btcUsd : null,
      CurrencyCodes.eth => rates.ethUsd > 0 ? amount * rates.ethUsd : null,
      CurrencyCodes.sol => rates.solUsd > 0 ? amount * rates.solUsd : null,
      _ => null,
    };
  }

  double? _fromUsd(double usd, String field, CurrencyRates rates) {
    return switch (field) {
      CurrencyCodes.usd => usd,
      'VES_BCV' => rates.bcvRate > 0 ? usd * rates.bcvRate : null,
      'VES_PARALLEL' =>
        rates.parallelRate > 0 ? usd * rates.parallelRate : null,
      CurrencyCodes.btc => rates.btcUsd > 0 ? usd / rates.btcUsd : null,
      CurrencyCodes.eth => rates.ethUsd > 0 ? usd / rates.ethUsd : null,
      CurrencyCodes.sol => rates.solUsd > 0 ? usd / rates.solUsd : null,
      _ => null,
    };
  }
}

final calculatorProvider =
    NotifierProvider<CalculatorNotifier, CalculatorState>(
  CalculatorNotifier.new,
);
