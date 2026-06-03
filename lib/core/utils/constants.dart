// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

// ─────────────────────────────────────────────
//  Supported currency codes
// ─────────────────────────────────────────────
class CurrencyCodes {
  CurrencyCodes._();

  static const String usd = 'USD';
  static const String ves = 'VES';
  static const String btc = 'BTC';
  static const String eth = 'ETH';
  static const String sol = 'SOL';

  static const List<String> all = [usd, ves, btc, eth, sol];
  static const List<String> fiat = [usd, ves];
  static const List<String> crypto = [btc, eth, sol];

  static String label(String code) {
    return switch (code.toUpperCase()) {
      'USD' => 'Dólar estadounidense',
      'VES' => 'Bolívar venezolano',
      'BTC' => 'Bitcoin',
      'ETH' => 'Ethereum',
      'SOL' => 'Solana',
      _ => code,
    };
  }

  static String symbol(String code) {
    return switch (code.toUpperCase()) {
      'USD' => '\$',
      'VES' => 'Bs.',
      'BTC' => '₿',
      'ETH' => 'Ξ',
      'SOL' => '◎',
      _ => code,
    };
  }

  static String flag(String code) {
    return switch (code.toUpperCase()) {
      'USD' => '🇺🇸',
      'VES' => '🇻🇪',
      'BTC' => '🟠',
      'ETH' => '🔷',
      'SOL' => '🟣',
      _ => '💱',
    };
  }
}

// ─────────────────────────────────────────────
//  Payment methods
// ─────────────────────────────────────────────
enum PaymentMethod {
  cash,
  pagoMovil,
  transfer,
  zelle,
  other;

  String get key => switch (this) {
    PaymentMethod.cash => 'cash',
    PaymentMethod.pagoMovil => 'pago_movil',
    PaymentMethod.transfer => 'transfer',
    PaymentMethod.zelle => 'zelle',
    PaymentMethod.other => 'other',
  };

  String get label => switch (this) {
    PaymentMethod.cash => 'Efectivo',
    PaymentMethod.pagoMovil => 'Pago Móvil',
    PaymentMethod.transfer => 'Transferencia',
    PaymentMethod.zelle => 'Zelle',
    PaymentMethod.other => 'Otro',
  };

  String get emoji => switch (this) {
    PaymentMethod.cash => '💵',
    PaymentMethod.pagoMovil => '📱',
    PaymentMethod.transfer => '🏦',
    PaymentMethod.zelle => '💸',
    PaymentMethod.other => '📦',
  };

  static PaymentMethod fromKey(String key) {
    return PaymentMethod.values.firstWhere(
      (e) => e.key == key,
      orElse: () => PaymentMethod.other,
    );
  }
}

// ─────────────────────────────────────────────
//  Transaction types
// ─────────────────────────────────────────────
enum TransactionType {
  income,
  expense;

  String get key => name;

  String get label => switch (this) {
    TransactionType.income => 'Ingreso',
    TransactionType.expense => 'Gasto',
  };

  static TransactionType fromKey(String key) {
    return TransactionType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => TransactionType.expense,
    );
  }
}

// ─────────────────────────────────────────────
//  Priority levels
// ─────────────────────────────────────────────
enum PriorityLevel {
  high,
  medium,
  low;

  String get key => name;

  String get label => switch (this) {
    PriorityLevel.high => 'Alta',
    PriorityLevel.medium => 'Media',
    PriorityLevel.low => 'Baja',
  };

  String get emoji => switch (this) {
    PriorityLevel.high => '🔴',
    PriorityLevel.medium => '🟡',
    PriorityLevel.low => '🟢',
  };

  static PriorityLevel fromKey(String key) {
    return PriorityLevel.values.firstWhere(
      (e) => e.key == key,
      orElse: () => PriorityLevel.medium,
    );
  }
}

// ─────────────────────────────────────────────
//  API endpoints
// ─────────────────────────────────────────────
class ApiEndpoints {
  ApiEndpoints._();

  static const String bcvRate =
      'https://ve.dolarapi.com/v1/dolares/oficial';
  static const String parallelRate =
      'https://ve.dolarapi.com/v1/dolares/paralelo';
  static const String cryptoPrices =
      'https://api.coingecko.com/api/v3/simple/price'
      '?ids=bitcoin,ethereum,solana&vs_currencies=usd';
}

// ─────────────────────────────────────────────
//  Rate cache keys
// ─────────────────────────────────────────────
class RatePairs {
  RatePairs._();

  static const String bcv = 'USD_VES_BCV';
  static const String parallel = 'USD_VES_PARALLEL';
  static const String btc = 'BTC_USD';
  static const String eth = 'ETH_USD';
  static const String sol = 'SOL_USD';
}

// ─────────────────────────────────────────────
//  Notification channel IDs
// ─────────────────────────────────────────────
class NotificationChannels {
  NotificationChannels._();

  static const String dailyReminder = 'daily_reminder';
  static const String recurringExpense = 'recurring_expense';
  static const String priority = 'priority_reminder';
}

// ─────────────────────────────────────────────
//  Shared preferences / secure storage keys
// ─────────────────────────────────────────────
class StorageKeys {
  StorageKeys._();

  static const String pin = 'user_pin';
  static const String biometricEnabled = 'biometric_enabled';
  static const String selectedTheme = 'selected_theme_id';
  static const String dailyReminderTime = 'daily_reminder_time';
  static const String dailyReminderEnabled = 'daily_reminder_enabled';
  static const String onboardingComplete = 'onboarding_complete';
}

// ─────────────────────────────────────────────
//  Rate refresh interval
// ─────────────────────────────────────────────
const Duration kRateRefreshInterval = Duration(minutes: 30);
const Duration kRateStaleDuration = Duration(hours: 2);
