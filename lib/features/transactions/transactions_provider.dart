import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/daos/transaction_dao.dart';
import '../../core/database/daos/wallet_dao.dart';
import '../../core/database/daos/category_dao.dart';
import '../../core/models/transaction.dart' as app_models;
import '../../core/models/category.dart';
import '../../core/models/currency_rates.dart';
import '../../core/providers/rate_provider.dart';
import '../../core/utils/constants.dart';

class TransactionFilter {
  const TransactionFilter({
    this.walletId,
    this.categoryId,
    this.type,
    this.paymentMethod,
    this.dateFrom,
    this.dateTo,
    this.searchNote,
  });

  final int? walletId;
  final int? categoryId;
  final TransactionType? type;
  final PaymentMethod? paymentMethod;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? searchNote;

  bool get isActive =>
      walletId != null ||
      categoryId != null ||
      type != null ||
      paymentMethod != null ||
      dateFrom != null ||
      dateTo != null ||
      (searchNote != null && searchNote!.isNotEmpty);

  TransactionFilter copyWith({
    int? walletId,
    int? categoryId,
    TransactionType? type,
    PaymentMethod? paymentMethod,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? searchNote,
    bool clearWallet = false,
    bool clearCategory = false,
    bool clearType = false,
    bool clearPaymentMethod = false,
    bool clearDates = false,
    bool clearSearch = false,
  }) {
    return TransactionFilter(
      walletId: clearWallet ? null : walletId ?? this.walletId,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      type: clearType ? null : type ?? this.type,
      paymentMethod:
          clearPaymentMethod ? null : paymentMethod ?? this.paymentMethod,
      dateFrom: clearDates ? null : dateFrom ?? this.dateFrom,
      dateTo: clearDates ? null : dateTo ?? this.dateTo,
      searchNote: clearSearch ? null : searchNote ?? this.searchNote,
    );
  }

  static const empty = TransactionFilter();
}

class TransactionsState {
  const TransactionsState({
    required this.transactions,
    required this.filter,
    required this.rates,
    required this.categories,
  });

  final List<app_models.Transaction> transactions;
  final TransactionFilter filter;
  final CurrencyRates rates;
  final List<Category> categories;

  bool get hasFilter => filter.isActive;

  static final empty = TransactionsState(
    transactions: const [],
    filter: TransactionFilter.empty,
    rates: CurrencyRates.empty,
    categories: const [],
  );
}

class TransactionsNotifier extends AsyncNotifier<TransactionsState> {
  final _txDao = TransactionDao.instance;
  final _walletDao = WalletDao.instance;
  final _categoryDao = CategoryDao.instance;

  TransactionFilter _filter = TransactionFilter.empty;

  @override
  Future<TransactionsState> build() async {
    final rates = ref.watch(currencyRatesProvider);
    return _load(rates);
  }

  Future<TransactionsState> _load(CurrencyRates rates) async {
    final txs = await _txDao.getFiltered(
      walletId: _filter.walletId,
      categoryId: _filter.categoryId,
      type: _filter.type?.key,
      paymentMethod: _filter.paymentMethod?.key,
      dateFrom: _filter.dateFrom,
      dateTo: _filter.dateTo,
      searchNote: _filter.searchNote,
    );

    final allCategories = await _categoryDao.getAll();
    final catMap = {for (final c in allCategories) c.id!: c};
    final enriched = <app_models.Transaction>[];
    for (final tx in txs) {
      final cat = tx.categoryId != null ? catMap[tx.categoryId] : null;
      enriched.add(tx.copyWith(category: cat));
    }

    return TransactionsState(
      transactions: enriched,
      filter: _filter,
      rates: rates,
      categories: allCategories,
    );
  }

  void setFilter(TransactionFilter filter) {
    _filter = filter;
    ref.invalidateSelf();
  }

  void clearFilter() {
    _filter = TransactionFilter.empty;
    ref.invalidateSelf();
  }

  Future<void> addTransaction(app_models.Transaction tx) async {
    await _txDao.insert(tx);
    final delta = tx.isIncome ? tx.amount : -tx.amount;
    await _walletDao.adjustBalance(tx.walletId, delta);
    _invalidateRelated();
    ref.invalidateSelf();
  }

  Future<void> updateTransaction(
      app_models.Transaction original, app_models.Transaction updated) async {
    final reverseDelta = original.isIncome ? -original.amount : original.amount;
    await _walletDao.adjustBalance(original.walletId, reverseDelta);
    final newDelta = updated.isIncome ? updated.amount : -updated.amount;
    await _walletDao.adjustBalance(updated.walletId, newDelta);
    await _txDao.update(updated);
    _invalidateRelated();
    ref.invalidateSelf();
  }

  Future<void> deleteTransaction(app_models.Transaction tx) async {
    final reverseDelta = tx.isIncome ? -tx.amount : tx.amount;
    await _walletDao.adjustBalance(tx.walletId, reverseDelta);
    await _txDao.delete(tx.id!);
    _invalidateRelated();
    ref.invalidateSelf();
  }

  void _invalidateRelated() {
    ref.invalidate(walletsInvalidatorProvider);
    // Increment so ref.watch detects a real change
    ref.read(dashboardInvalidatorProvider.notifier).state++;
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, TransactionsState>(
  TransactionsNotifier.new,
);

final walletsInvalidatorProvider = StateProvider<int>((ref) => 0);
final dashboardInvalidatorProvider = StateProvider<int>((ref) => 0);