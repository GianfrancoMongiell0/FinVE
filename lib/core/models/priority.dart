// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import '../utils/constants.dart';

class Priority {
  const Priority({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.currencyCode,
    required this.priorityLevel,
    required this.isCompleted,
    this.notes,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final double targetAmount;
  final String currencyCode;
  final PriorityLevel priorityLevel;
  final bool isCompleted;
  final String? notes;
  final DateTime createdAt;

  // ─────────────────────────────────────────────
  //  Serialisation
  // ─────────────────────────────────────────────
  factory Priority.fromMap(Map<String, dynamic> map) {
    return Priority(
      id: map['id'] as int?,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currencyCode:
          map['currency_code'] as String? ?? CurrencyCodes.usd,
      priorityLevel: PriorityLevel.fromKey(
        map['priority_level'] as String? ?? 'medium',
      ),
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'target_amount': targetAmount,
      'currency_code': currencyCode,
      'priority_level': priorityLevel.key,
      'is_completed': isCompleted ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─────────────────────────────────────────────
  //  copyWith
  // ─────────────────────────────────────────────
  Priority copyWith({
    int? id,
    String? name,
    double? targetAmount,
    String? currencyCode,
    PriorityLevel? priorityLevel,
    bool? isCompleted,
    String? notes,
    DateTime? createdAt,
  }) {
    return Priority(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────
  bool get isHigh => priorityLevel == PriorityLevel.high;
  bool get isMedium => priorityLevel == PriorityLevel.medium;
  bool get isLow => priorityLevel == PriorityLevel.low;

  @override
  String toString() =>
      'Priority(id: $id, name: $name, level: ${priorityLevel.key}, '
      'amount: $targetAmount $currencyCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Priority && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
