// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  // ─────────────────────────────────────────────
  //  Fiat formatters
  // ─────────────────────────────────────────────

  /// $1,250.00
  static String usd(double amount) {
    return NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    ).format(amount);
  }

  /// Bs. 45,600.00
  static String ves(double amount) {
    return 'Bs. ${NumberFormat('#,##0.00').format(amount)}';
  }

  /// Generic fiat with custom symbol
  static String fiat(double amount, String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return usd(amount);
      case 'VES':
        return ves(amount);
      default:
        return '${currencyCode.toUpperCase()} ${NumberFormat('#,##0.00').format(amount)}';
    }
  }

  // ─────────────────────────────────────────────
  //  Crypto formatters (6 decimal places)
  // ─────────────────────────────────────────────

  /// 0.002341 BTC
  static String btc(double amount) => _crypto(amount, 'BTC');

  /// 0.123456 ETH
  static String eth(double amount) => _crypto(amount, 'ETH');

  /// 1.234567 SOL
  static String sol(double amount) => _crypto(amount, 'SOL');

  static String _crypto(double amount, String symbol) {
    final formatted = NumberFormat('#,##0.000000').format(amount);
    return '$formatted $symbol';
  }

  /// Dispatch by currency code
  static String byCurrency(double amount, String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return usd(amount);
      case 'VES':
        return ves(amount);
      case 'BTC':
        return btc(amount);
      case 'ETH':
        return eth(amount);
      case 'SOL':
        return sol(amount);
      default:
        return fiat(amount, currencyCode);
    }
  }

  // ─────────────────────────────────────────────
  //  Rate display  (e.g. "36.50 Bs/USD")
  // ─────────────────────────────────────────────
  static String rate(double rate, {String label = 'Bs/USD'}) {
    return '${NumberFormat('#,##0.00').format(rate)} $label';
  }

  // ─────────────────────────────────────────────
  //  Compact amount (for widgets / small spaces)
  //  e.g. 1250.00 → "$1.25K"
  // ─────────────────────────────────────────────
  static String compactUsd(double amount) {
    if (amount.abs() >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(2)}M';
    }
    if (amount.abs() >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return usd(amount);
  }

  // ─────────────────────────────────────────────
  //  Date formatters
  // ─────────────────────────────────────────────

  /// "Hoy", "Ayer", or "15 ene" / "15 ene 2023"
  static String transactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (date.year == now.year) {
      return DateFormat('d MMM', 'es').format(date);
    }
    return DateFormat('d MMM yyyy', 'es').format(date);
  }

  /// Full: "lunes, 15 de enero de 2024"
  static String fullDate(DateTime date) {
    return DateFormat('EEEE, d \'de\' MMMM \'de\' y', 'es').format(date);
  }

  /// Short: "15/01/2024"
  static String shortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Time: "14:35"
  static String time(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// "hace 5 min", "hace 2 h", "hace 3 d"
  static String timeAgo(DateTime from) {
    final diff = DateTime.now().difference(from);
    if (diff.inMinutes < 1) return 'ahora mismo';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }
}
