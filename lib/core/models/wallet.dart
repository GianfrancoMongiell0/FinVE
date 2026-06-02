import '../../core/utils/constants.dart';

class Wallet {
  const Wallet({
    this.id,
    required this.name,
    required this.currencyCode,
    required this.balance,
    required this.icon,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String currencyCode;
  final double balance;
  final String icon;
  final DateTime createdAt;

  // ─────────────────────────────────────────────
  //  Serialisation
  // ─────────────────────────────────────────────
  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as int?,
      name: map['name'] as String,
      currencyCode: map['currency_code'] as String? ?? CurrencyCodes.usd,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      icon: map['icon'] as String? ?? 'wallet',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'currency_code': currencyCode,
      'balance': balance,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─────────────────────────────────────────────
  //  copyWith
  // ─────────────────────────────────────────────
  Wallet copyWith({
    int? id,
    String? name,
    String? currencyCode,
    double? balance,
    String? icon,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      currencyCode: currencyCode ?? this.currencyCode,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────
  bool get isCrypto => CurrencyCodes.crypto.contains(currencyCode);
  bool get isFiat => CurrencyCodes.fiat.contains(currencyCode);

  @override
  String toString() =>
      'Wallet(id: $id, name: $name, currency: $currencyCode, balance: $balance)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
