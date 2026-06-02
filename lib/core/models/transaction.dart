import '../utils/constants.dart';
import 'category.dart';
import 'wallet.dart';

class Transaction {
  const Transaction({
    this.id,
    required this.walletId,
    required this.amount,
    required this.type,
    this.categoryId,
    required this.paymentMethod,
    this.note,
    required this.date,
    required this.createdAt,
    // Joined fields (not stored in DB directly)
    this.category,
    this.wallet,
  });

  final int? id;
  final int walletId;
  final double amount;
  final TransactionType type;
  final int? categoryId;
  final PaymentMethod paymentMethod;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  // Optional joined objects (populated by DAO when needed)
  final Category? category;
  final Wallet? wallet;

  // ─────────────────────────────────────────────
  //  Serialisation
  // ─────────────────────────────────────────────
  factory Transaction.fromMap(
    Map<String, dynamic> map, {
    Category? category,
    Wallet? wallet,
  }) {
    return Transaction(
      id: map['id'] as int?,
      walletId: map['wallet_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.fromKey(map['type'] as String? ?? 'expense'),
      categoryId: map['category_id'] as int?,
      paymentMethod:
          PaymentMethod.fromKey(map['payment_method'] as String? ?? 'cash'),
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      category: category,
      wallet: wallet,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'wallet_id': walletId,
      'amount': amount,
      'type': type.key,
      'category_id': categoryId,
      'payment_method': paymentMethod.key,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─────────────────────────────────────────────
  //  copyWith
  // ─────────────────────────────────────────────
  Transaction copyWith({
    int? id,
    int? walletId,
    double? amount,
    TransactionType? type,
    int? categoryId,
    PaymentMethod? paymentMethod,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    Category? category,
    Wallet? wallet,
  }) {
    return Transaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      wallet: wallet ?? this.wallet,
    );
  }

  // ─────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────
  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  /// Signed amount: positive for income, negative for expense.
  double get signedAmount => isIncome ? amount : -amount;

  @override
  String toString() =>
      'Transaction(id: $id, type: ${type.key}, amount: $amount, date: $date)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
