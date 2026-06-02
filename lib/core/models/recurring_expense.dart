import '../utils/constants.dart';
import 'category.dart';
import 'wallet.dart';

class RecurringExpense {
  const RecurringExpense({
    this.id,
    required this.name,
    required this.amount,
    required this.currencyCode,
    required this.walletId,
    this.categoryId,
    required this.paymentMethod,
    required this.dayOfMonth,
    required this.autoRegister,
    this.lastTriggeredAt,
    required this.createdAt,
    // Optional joined objects
    this.category,
    this.wallet,
  });

  final int? id;
  final String name;
  final double amount;
  final String currencyCode;
  final int walletId;
  final int? categoryId;
  final PaymentMethod paymentMethod;

  /// 1–31: day of the month this expense is due.
  final int dayOfMonth;

  /// If true, transaction is auto-registered when due.
  final bool autoRegister;
  final DateTime? lastTriggeredAt;
  final DateTime createdAt;

  // Optional joined objects
  final Category? category;
  final Wallet? wallet;

  // ─────────────────────────────────────────────
  //  Serialisation
  // ─────────────────────────────────────────────
  factory RecurringExpense.fromMap(
    Map<String, dynamic> map, {
    Category? category,
    Wallet? wallet,
  }) {
    final lastTriggeredRaw = map['last_triggered_at'] as String?;
    return RecurringExpense(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      currencyCode:
          map['currency_code'] as String? ?? CurrencyCodes.usd,
      walletId: map['wallet_id'] as int,
      categoryId: map['category_id'] as int?,
      paymentMethod:
          PaymentMethod.fromKey(map['payment_method'] as String? ?? 'cash'),
      dayOfMonth: map['day_of_month'] as int,
      autoRegister: (map['auto_register'] as int? ?? 0) == 1,
      lastTriggeredAt: lastTriggeredRaw != null
          ? DateTime.tryParse(lastTriggeredRaw)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      category: category,
      wallet: wallet,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'amount': amount,
      'currency_code': currencyCode,
      'wallet_id': walletId,
      'category_id': categoryId,
      'payment_method': paymentMethod.key,
      'day_of_month': dayOfMonth,
      'auto_register': autoRegister ? 1 : 0,
      'last_triggered_at': lastTriggeredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─────────────────────────────────────────────
  //  copyWith
  // ─────────────────────────────────────────────
  RecurringExpense copyWith({
    int? id,
    String? name,
    double? amount,
    String? currencyCode,
    int? walletId,
    int? categoryId,
    PaymentMethod? paymentMethod,
    int? dayOfMonth,
    bool? autoRegister,
    DateTime? lastTriggeredAt,
    DateTime? createdAt,
    Category? category,
    Wallet? wallet,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      autoRegister: autoRegister ?? this.autoRegister,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      wallet: wallet ?? this.wallet,
    );
  }

  // ─────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────

  /// Returns true if this expense has already been triggered this month.
  bool get wasTriggeredThisMonth {
    if (lastTriggeredAt == null) return false;
    final now = DateTime.now();
    return lastTriggeredAt!.year == now.year &&
        lastTriggeredAt!.month == now.month;
  }

  /// Returns the next due date (this month if not yet triggered, next month if it was).
  DateTime get nextDueDate {
    final now = DateTime.now();
    final thisMonthDue = DateTime(now.year, now.month, dayOfMonth);
    if (!wasTriggeredThisMonth && thisMonthDue.isAfter(now) ||
        thisMonthDue.day == now.day) {
      return thisMonthDue;
    }
    return DateTime(now.year, now.month + 1, dayOfMonth);
  }

  /// Days until next due date (0 = today, negative = past due this month).
  int get daysUntilDue {
    return nextDueDate.difference(DateTime.now()).inDays;
  }

  @override
  String toString() =>
      'RecurringExpense(id: $id, name: $name, amount: $amount $currencyCode, '
      'day: $dayOfMonth, auto: $autoRegister)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringExpense &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
