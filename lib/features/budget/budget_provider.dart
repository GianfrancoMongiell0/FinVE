// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/daos/budget_dao.dart';
import '../../core/database/daos/category_dao.dart';
import '../../core/database/daos/transaction_dao.dart';
import '../../core/models/budget.dart';
import '../../core/models/category.dart';
import '../../core/utils/constants.dart';

class BudgetState {
  const BudgetState({
    required this.budgets,
    required this.categories,
    required this.month,
    required this.year,
  });

  final List<Budget> budgets;
  final List<Category> categories;
  final int month;
  final int year;

  List<Budget> get overBudget => budgets.where((b) => b.isOverBudget).toList();
  List<Budget> get warning => budgets.where((b) => b.isWarning).toList();
  List<Budget> get ok => budgets.where((b) => b.isOk).toList();

  double get totalBudgeted =>
      budgets.fold(0, (sum, b) => sum + b.amount);
  double get totalSpent =>
      budgets.fold(0, (sum, b) => sum + b.spent);
}

class BudgetNotifier extends AsyncNotifier<BudgetState> {
  final _dao = BudgetDao.instance;
  final _categoryDao = CategoryDao.instance;
  final _txDao = TransactionDao.instance;

  late int _month;
  late int _year;

  @override
  Future<BudgetState> build() async {
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    return _load();
  }

  Future<BudgetState> _load() async {
    final budgets = await _dao.getForMonth(_month, _year);
    final categories = await _categoryDao.getAll();
    final catMap = {for (final c in categories) c.id!: c};

    // Calculate spent for each budget
    final now = DateTime.now();
    final from = DateTime(_year, _month, 1);
    final to = DateTime(_year, _month + 1, 0, 23, 59, 59);

    final enriched = <Budget>[];
    for (final b in budgets) {
      final txs = await _txDao.getFiltered(
        categoryId: b.categoryId,
        type: TransactionType.expense.key,
        dateFrom: from,
        dateTo: to,
      );
      final spent = txs.fold(0.0, (sum, tx) => sum + tx.amount);
      final cat = catMap[b.categoryId];
      enriched.add(b.copyWith(spent: spent, category: cat));
    }

    // Sort: over budget first, then warning, then ok
    enriched.sort((a, b) {
      if (a.isOverBudget && !b.isOverBudget) return -1;
      if (!a.isOverBudget && b.isOverBudget) return 1;
      if (a.isWarning && !b.isWarning) return -1;
      if (!a.isWarning && b.isWarning) return 1;
      return b.percentage.compareTo(a.percentage);
    });

    return BudgetState(
      budgets: enriched,
      categories: categories
          .where((c) => c.type == 'expense' || c.type == 'both')
          .toList(),
      month: _month,
      year: _year,
    );
  }

  void setMonth(int month, int year) {
    _month = month;
    _year = year;
    ref.invalidateSelf();
  }

  Future<void> saveBudget(Budget budget) async {
    final existing = await _dao.getForCategory(
        budget.categoryId, budget.month, budget.year);
    if (existing != null) {
      await _dao.update(budget.copyWith(id: existing.id));
    } else {
      await _dao.insert(budget);
    }
    ref.invalidateSelf();
  }

  Future<void> deleteBudget(int id) async {
    await _dao.delete(id);
    ref.invalidateSelf();
  }
}

final budgetProvider =
    AsyncNotifierProvider<BudgetNotifier, BudgetState>(
  BudgetNotifier.new,
);
