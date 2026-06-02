import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  DateTime extensions
// ─────────────────────────────────────────────
extension DateTimeX on DateTime {
  /// True if same calendar day as [other]
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// True if this date is today
  bool get isToday => isSameDay(DateTime.now());

  /// True if this date is yesterday
  bool get isYesterday =>
      isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  /// Start of day (00:00:00.000)
  DateTime get startOfDay => DateTime(year, month, day);

  /// End of day (23:59:59.999)
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Start of current month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// End of current month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// ISO 8601 date string "2024-01-15"
  String get isoDate =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// Returns true if within the next [days] days (inclusive today)
  bool isWithinNextDays(int days) {
    final now = DateTime.now().startOfDay;
    final limit = now.add(Duration(days: days));
    return !isBefore(now) && isBefore(limit);
  }

  /// Days until this date from today (negative if past)
  int get daysFromNow {
    final now = DateTime.now().startOfDay;
    return startOfDay.difference(now).inDays;
  }
}

// ─────────────────────────────────────────────
//  double extensions
// ─────────────────────────────────────────────
extension DoubleX on double {
  /// Rounds to [decimals] decimal places
  double roundTo(int decimals) {
    final factor = 10.0 * decimals;
    return (this * factor).round() / factor;
  }

  /// True if effectively zero (within floating-point tolerance)
  bool get isEffectivelyZero => this.abs() < 1e-10;

  /// Absolute value shorthand
  double get absValue => isNegative ? -this : this;
}

// ─────────────────────────────────────────────
//  String extensions
// ─────────────────────────────────────────────
extension StringX on String {
  /// Capitalize first letter only
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// True if parses as a valid positive double
  bool get isValidAmount {
    final v = double.tryParse(replaceAll(',', '.'));
    return v != null && v > 0;
  }

  /// Parse as double, replacing commas (for Latin American input)
  double get toAmount => double.tryParse(replaceAll(',', '.')) ?? 0.0;
}

// ─────────────────────────────────────────────
//  BuildContext extensions
// ─────────────────────────────────────────────
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Color extensions
// ─────────────────────────────────────────────
extension ColorX on Color {
  /// Returns a version of this color with modified opacity
  Color withAlpha(double opacity) => withValues(alpha: opacity);
}
