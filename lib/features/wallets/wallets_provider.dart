// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/dashboard_provider.dart';
import '../../core/database/daos/wallet_dao.dart';
import '../../core/database/daos/transaction_dao.dart';
import '../../core/models/wallet.dart';
import '../../core/models/currency_rates.dart';
import '../../core/providers/rate_provider.dart';
import '../../core/utils/constants.dart';
import '../transactions/transactions_provider.dart';

// ─────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────
class WalletsState {
  const WalletsState({
    required this.wallets,
    required this.rates,
  });

  final List<Wallet> wallets;
  final CurrencyRates rates;

  double get totalUsd {
    double total = 0;
    for (final w in wallets) {
      total += rates.toUsd(w.balance, w.currencyCode) ?? 0;
    }
    return total;
  }

  double usdEquivalent(Wallet w) =>
      rates.toUsd(w.balance, w.currencyCode) ?? 0;

  static final empty = WalletsState(
    wallets: [],
    rates: CurrencyRates(
      bcvRate: 0, parallelRate: 0,
      btcUsd: 0, ethUsd: 0, solUsd: 0,
      fetchedAt: DateTime(2020),
    ),
  );
}

// ─────────────────────────────────────────────
//  Notifier
// ─────────────────────────────────────────────
class WalletsNotifier extends AsyncNotifier<WalletsState> {
  final WalletDao _dao = WalletDao.instance;

  @override
  Future<WalletsState> build() async {
    ref.watch(walletsInvalidatorProvider);
    final rates = ref.watch(currencyRatesProvider);
    final wallets = await _dao.getAll();
    return WalletsState(wallets: wallets, rates: rates);
  }

  // ── CRUD ─────────────────────────────────────

  void _invalidateDashboard() {
    // Increment so ref.watch detects a real change
    ref.read(dashboardInvalidatorProvider.notifier).state++;
  }

  Future<int> addWallet(Wallet wallet) async {
    final id = await _dao.insert(wallet);
    ref.invalidateSelf();
    _invalidateDashboard();
    return id;
  }

  Future<void> updateWallet(Wallet wallet) async {
    await _dao.update(wallet);
    ref.invalidateSelf();
    _invalidateDashboard();
  }

  Future<bool> deleteWallet(int id) async {
    final txCount = await TransactionDao.instance.count(walletId: id);
    if (txCount > 0) {
      await _dao.delete(id);
      ref.invalidateSelf();
      _invalidateDashboard();
      return true;
    }
    await _dao.delete(id);
    ref.invalidateSelf();
    _invalidateDashboard();
    return true;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    _invalidateDashboard();
  }
}

final walletsProvider =
    AsyncNotifierProvider<WalletsNotifier, WalletsState>(
  WalletsNotifier.new,
);

// Convenience: just the list of wallets
final walletListProvider = Provider<List<Wallet>>((ref) {
  return ref.watch(walletsProvider).valueOrNull?.wallets ?? [];
});