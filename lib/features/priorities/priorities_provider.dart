import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/daos/priority_dao.dart';
import '../../core/models/priority.dart';
import '../../core/models/currency_rates.dart';
import '../../core/models/wallet.dart';
import '../../core/providers/rate_provider.dart';
import '../../core/utils/constants.dart';
import '../wallets/wallets_provider.dart';

// ─────────────────────────────────────────────
//  Affordability result
// ─────────────────────────────────────────────
class AffordResult {
  const AffordResult({
    required this.priority,
    required this.targetUsd,
    required this.canAfford,
    required this.shortfallUsd,
    required this.balanceAfterUsd,
  });

  final Priority priority;

  /// Target converted to USD.
  final double targetUsd;

  /// True if current total balance covers this item without going negative.
  final bool canAfford;

  /// How much more is needed (0 if canAfford).
  final double shortfallUsd;

  /// Remaining balance after paying this item (may be negative).
  final double balanceAfterUsd;
}

// ─────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────
class PrioritiesState {
  const PrioritiesState({
    required this.pending,
    required this.completed,
    required this.rates,
    required this.totalBalanceUsd,
    required this.wallets,
  });

  final List<Priority> pending;
  final List<Priority> completed;
  final CurrencyRates rates;
  final double totalBalanceUsd;
  final List<Wallet> wallets;

  // Grouped pending items
  List<Priority> get highPriority =>
      pending.where((p) => p.priorityLevel == PriorityLevel.high).toList();
  List<Priority> get mediumPriority =>
      pending.where((p) => p.priorityLevel == PriorityLevel.medium).toList();
  List<Priority> get lowPriority =>
      pending.where((p) => p.priorityLevel == PriorityLevel.low).toList();

  double targetUsd(Priority p) =>
      rates.toUsd(p.targetAmount, p.currencyCode) ?? p.targetAmount;

  /// Progress ratio: totalBalanceUsd / targetUsd (clamped 0–1).
  double progressFor(Priority p) {
    final target = targetUsd(p);
    if (target <= 0) return 1.0;
    return (totalBalanceUsd / target).clamp(0.0, 1.0);
  }

  bool canAfford(Priority p) => totalBalanceUsd >= targetUsd(p);

  double shortfall(Priority p) {
    final diff = targetUsd(p) - totalBalanceUsd;
    return diff > 0 ? diff : 0;
  }
}

// ─────────────────────────────────────────────
//  Notifier
// ─────────────────────────────────────────────
class PrioritiesNotifier extends AsyncNotifier<PrioritiesState> {
  final _dao = PriorityDao.instance;

  @override
  Future<PrioritiesState> build() async {
    final rates = ref.watch(currencyRatesProvider);
    final walletsState = ref.watch(walletsProvider).valueOrNull;
    final wallets = walletsState?.wallets ?? [];
    final totalUsd = walletsState?.totalUsd ?? 0.0;
    return _load(rates, wallets, totalUsd);
  }

  Future<PrioritiesState> _load(
    CurrencyRates rates,
    List<Wallet> wallets,
    double totalUsd,
  ) async {
    final pending = await _dao.getPending();
    final completed = await _dao.getCompleted();
    return PrioritiesState(
      pending: pending,
      completed: completed,
      rates: rates,
      totalBalanceUsd: totalUsd,
      wallets: wallets,
    );
  }

  // ── CRUD ─────────────────────────────────────
  Future<void> add(Priority priority) async {
    await _dao.insert(priority);
    ref.invalidateSelf();
  }

  Future<void> updatePriority(Priority priority) async {
    await _dao.update(priority);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await _dao.delete(id);
    ref.invalidateSelf();
  }

  Future<void> toggleCompleted(Priority p) async {
    await _dao.markCompleted(p.id!, completed: !p.isCompleted);
    ref.invalidateSelf();
  }

  // ── "Can I afford it?" logic ──────────────────

  /// Returns an ordered list of AffordResult for ALL pending items,
  /// simulating paying them one by one in priority order (high → medium → low).
  List<AffordResult> computeAffordability(PrioritiesState state) {
    final results = <AffordResult>[];
    double remainingBalance = state.totalBalanceUsd;

    // Process in priority order
    final ordered = [
      ...state.highPriority,
      ...state.mediumPriority,
      ...state.lowPriority,
    ];

    for (final p in ordered) {
      final targetUsd =
          state.rates.toUsd(p.targetAmount, p.currencyCode) ??
              p.targetAmount;
      final canAfford = remainingBalance >= targetUsd;
      final balanceAfter = remainingBalance - targetUsd;
      final shortfall = canAfford ? 0.0 : targetUsd - remainingBalance;

      results.add(AffordResult(
        priority: p,
        targetUsd: targetUsd,
        canAfford: canAfford,
        shortfallUsd: shortfall,
        balanceAfterUsd: balanceAfter,
      ));

      // Only deduct if can afford — keeps simulation realistic
      if (canAfford) remainingBalance -= targetUsd;
    }

    return results;
  }
}

final prioritiesProvider =
    AsyncNotifierProvider<PrioritiesNotifier, PrioritiesState>(
  PrioritiesNotifier.new,
);
