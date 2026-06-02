class Budget {
  const Budget({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.currencyCode,
    required this.month,
    required this.year,
    required this.createdAt,
    this.category,
    this.spent = 0,
  });

  final int? id;
  final int categoryId;
  final double amount;
  final String currencyCode;
  final int month;
  final int year;
  final DateTime createdAt;
  final dynamic category; // Category model
  final double spent;

  double get percentage => amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0;
  double get remaining => (amount - spent).clamp(0, double.infinity);
  bool get isOverBudget => spent > amount;
  bool get isWarning => percentage >= 0.8 && !isOverBudget;
  bool get isOk => percentage < 0.8;

  Budget copyWith({
    int? id,
    int? categoryId,
    double? amount,
    String? currencyCode,
    int? month,
    int? year,
    DateTime? createdAt,
    dynamic category,
    double? spent,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      spent: spent ?? this.spent,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category_id': categoryId,
        'amount': amount,
        'currency_code': currencyCode,
        'month': month,
        'year': year,
        'created_at': createdAt.toIso8601String(),
      };

  factory Budget.fromMap(Map<String, dynamic> m) => Budget(
        id: m['id'] as int?,
        categoryId: m['category_id'] as int,
        amount: (m['amount'] as num).toDouble(),
        currencyCode: m['currency_code'] as String,
        month: m['month'] as int,
        year: m['year'] as int,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
