class Category {
  const Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  final int? id;
  final String name;
  final String icon;

  /// Hex color string, e.g. '#FF6B35'
  final String color;

  /// 'income' | 'expense' | 'both'
  final String type;

  // ─────────────────────────────────────────────
  //  Serialisation
  // ─────────────────────────────────────────────
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '📦',
      color: map['color'] as String? ?? '#B0BEC5',
      type: map['type'] as String? ?? 'both',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
    };
  }

  // ─────────────────────────────────────────────
  //  copyWith
  // ─────────────────────────────────────────────
  Category copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    String? type,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }

  // ─────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────
  bool get isIncome => type == 'income' || type == 'both';
  bool get isExpense => type == 'expense' || type == 'both';

  @override
  String toString() =>
      'Category(id: $id, name: $name, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
