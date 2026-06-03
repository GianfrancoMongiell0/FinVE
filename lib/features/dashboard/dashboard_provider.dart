// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/daos/wallet_dao.dart';
import '../../core/database/daos/transaction_dao.dart';
import '../../core/database/daos/category_dao.dart';
import '../../core/database/daos/recurring_expense_dao.dart';
import '../../core/models/wallet.dart';
import '../../core/models/transaction.dart' as app_models;
import '../../core/models/category.dart';
import '../../core/models/recurring_expense.dart';
import '../../core/models/currency_rates.dart';
import '../../core/providers/rate_provider.dart';
import '../../core/utils/constants.dart';
import '../transactions/transactions_provider.dart';

// ─────────────────────────────────────────────
//  Data classes
// ─────────────────────────────────────────────
class WalletSummary {
  const WalletSummary({required this.wallet, required this.usdEquivalent});
  final Wallet wallet;
  final double usdEquivalent;
}

class ChartPoint {
  const ChartPoint({required this.date, required this.balanceUsd});
  final DateTime date;
  final double balanceUsd;
}

class CategoryExpense {
  const CategoryExpense({
    required this.category,
    required this.totalUsd,
    required this.percentage,
  });
  final Category category;
  final double totalUsd;
  final double percentage;
}

class MonthlySummary {
  const MonthlySummary({
    required this.currentIncome,
    required this.currentExpense,
    required this.previousIncome,
    required this.previousExpense,
    required this.monthName,
  });

  final double currentIncome;
  final double currentExpense;
  final double previousIncome;
  final double previousExpense;
  final String monthName;

  double get currentNet => currentIncome - currentExpense;
  double get previousNet => previousIncome - previousExpense;

  double get expenseChange => previousExpense > 0
      ? ((currentExpense - previousExpense) / previousExpense) * 100
      : 0;
  double get incomeChange => previousIncome > 0
      ? ((currentIncome - previousIncome) / previousIncome) * 100
      : 0;
}

class DashboardState {
  const DashboardState({
    required this.wallets,
    required this.totalUsd,
    required this.totalVesBcv,
    required this.walletSummaries,
    required this.recentTransactions,
    required this.upcomingRecurring,
    required this.chartData,
    required this.rates,
    required this.categoryExpenses,
    required this.monthlySummary,
  });

  final List<Wallet> wallets;
  final double totalUsd;
  final double totalVesBcv;
  final List<WalletSummary> walletSummaries;
  final List<app_models.Transaction> recentTransactions;
  final List<RecurringExpense> upcomingRecurring;
  final List<ChartPoint> chartData;
  final CurrencyRates rates;
  final List<CategoryExpense> categoryExpenses;
  final MonthlySummary? monthlySummary;

  static final empty = DashboardState(
    wallets: const [],
    totalUsd: 0,
    totalVesBcv: 0,
    walletSummaries: const [],
    recentTransactions: const [],
    upcomingRecurring: const [],
    chartData: const [],
    categoryExpenses: const [],
    monthlySummary: null,
    rates: CurrencyRates(
      bcvRate: 0,
      parallelRate: 0,
      btcUsd: 0,
      ethUsd: 0,
      solUsd: 0,
      fetchedAt: DateTime(2020),
    ),
  );
}

// ─────────────────────────────────────────────
//  Notifier
// ─────────────────────────────────────────────
class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    ref.watch(dashboardInvalidatorProvider);
    final rates = ref.watch(currencyRatesProvider);
    return _load(rates);
  }

  Future<DashboardState> _load(CurrencyRates rates) async {
    final walletDao = WalletDao.instance;
    final txDao = TransactionDao.instance;
    final recurringDao = RecurringExpenseDao.instance;
    final categoryDao = CategoryDao.instance;

    final wallets = await walletDao.getAll();
    final recentTx = await txDao.getRecent(5);
    final upcoming = await recurringDao.getDueWithin(7);
    final dailyNet = await txDao.dailyNetAllWallets(days: 30);

    // Enrich recent tx with categories
    final allCategories = await categoryDao.getAll();
    final catMap = {for (final c in allCategories) c.id!: c};
    final recentEnriched = recentTx.map((tx) {
      final cat = tx.categoryId != null ? catMap[tx.categoryId] : null;
      return tx.copyWith(category: cat);
    }).toList();

    // Total balance in USD
    double totalUsd = 0;
    final summaries = <WalletSummary>[];
    for (final w in wallets) {
      final usd = rates.toUsd(w.balance, w.currencyCode) ?? 0;
      totalUsd += usd;
      summaries.add(WalletSummary(wallet: w, usdEquivalent: usd));
    }
    final totalVesBcv = rates.bcvRate > 0 ? totalUsd * rates.bcvRate : 0.0;

    // Chart data
    final chartData = _buildChartData(dailyNet, totalUsd);

    // Category expenses (this month)
    final categoryExpenses =
        await _buildCategoryExpenses(txDao, catMap, rates);

    // Monthly summary
    final monthlySummary = await _buildMonthlySummary(txDao);

    return DashboardState(
      wallets: wallets,
      totalUsd: totalUsd,
      totalVesBcv: totalVesBcv,
      walletSummaries: summaries,
      recentTransactions: recentEnriched,
      upcomingRecurring: upcoming,
      chartData: chartData,
      rates: rates,
      categoryExpenses: categoryExpenses,
      monthlySummary: monthlySummary,
    );
  }

  // ── Category expenses this month ─────────────
  Future<List<CategoryExpense>> _buildCategoryExpenses(
    TransactionDao txDao,
    Map<int, Category> catMap,
    CurrencyRates rates,
  ) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final txs = await txDao.getFiltered(
      type: TransactionType.expense.key,
      dateFrom: from,
      dateTo: to,
    );

    // Aggregate by category
    final Map<int, double> totals = {};
    double grandTotal = 0;

    for (final tx in txs) {
      final catId = tx.categoryId ?? -1;
      final usd = tx.amount; // already in wallet currency; approximate as USD
      totals[catId] = (totals[catId] ?? 0) + usd;
      grandTotal += usd;
    }

    if (grandTotal == 0) return [];

    final result = <CategoryExpense>[];
    totals.forEach((catId, total) {
      final cat = catId != -1
          ? catMap[catId]
          : Category(name: 'Sin categoría', icon: '📦', color: '#B0BEC5', type: 'expense');
      if (cat == null) return;
      result.add(CategoryExpense(
        category: cat,
        totalUsd: total,
        percentage: (total / grandTotal) * 100,
      ));
    });

    result.sort((a, b) => b.totalUsd.compareTo(a.totalUsd));
    return result.take(6).toList();
  }

  // ── Monthly summary ───────────────────────────
  Future<MonthlySummary> _buildMonthlySummary(TransactionDao txDao) async {
    final now = DateTime.now();

    // Current month
    final curFrom = DateTime(now.year, now.month, 1);
    final curTo = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Previous month
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final prevFrom = DateTime(prevYear, prevMonth, 1);
    final prevTo = DateTime(prevYear, prevMonth + 1, 0, 23, 59, 59);

    final curTotals = await txDao.sumByType(0, from: curFrom, to: curTo);
    final prevTotals = await txDao.sumByType(0, from: prevFrom, to: prevTo);

    // sumByType with walletId=0 won't work — query all wallets
    final curTxs = await txDao.getFiltered(dateFrom: curFrom, dateTo: curTo);
    final prevTxs = await txDao.getFiltered(dateFrom: prevFrom, dateTo: prevTo);

    double curIncome = 0, curExpense = 0;
    for (final tx in curTxs) {
      if (tx.isIncome) curIncome += tx.amount;
      else curExpense += tx.amount;
    }
    double prevIncome = 0, prevExpense = 0;
    for (final tx in prevTxs) {
      if (tx.isIncome) prevIncome += tx.amount;
      else prevExpense += tx.amount;
    }

    const months = ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
        'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];

    return MonthlySummary(
      currentIncome: curIncome,
      currentExpense: curExpense,
      previousIncome: prevIncome,
      previousExpense: prevExpense,
      monthName: months[now.month - 1],
    );
  }

  List<ChartPoint> _buildChartData(
    List<Map<String, dynamic>> dailyNet,
    double currentTotalUsd,
  ) {
    if (dailyNet.isEmpty) return [];
    final netByDay = <String, double>{};
    for (final row in dailyNet) {
      final day = row['day'] as String;
      final net = (row['net'] as num?)?.toDouble() ?? 0;
      netByDay[day] = net;
    }
    final today = DateTime.now();
    final points = <ChartPoint>[];
    double runningBalance = currentTotalUsd;
    for (var i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final dayKey =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      points.add(ChartPoint(date: date, balanceUsd: runningBalance));
      final net = netByDay[dayKey] ?? 0;
      runningBalance -= net;
    }
    return points.reversed.toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final rates = ref.read(currencyRatesProvider);
    state = await AsyncValue.guard(() => _load(rates));
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
