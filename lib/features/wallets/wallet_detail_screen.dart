import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/daos/transaction_dao.dart';
import '../../core/models/wallet.dart';
import '../../core/models/transaction.dart' as app_models;
import '../../core/models/currency_rates.dart';
import '../../core/providers/rate_provider.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/extensions.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/currency_badge.dart';
import '../../shared/widgets/payment_method_badge.dart';
import '../../shared/widgets/empty_state.dart';
import 'wallet_form_screen.dart';
import 'wallets_provider.dart';

// ─────────────────────────────────────────────
//  Providers
// ─────────────────────────────────────────────
final _walletTxProvider =
    FutureProvider.family<List<app_models.Transaction>, int>(
        (ref, walletId) async {
  return TransactionDao.instance.getFiltered(walletId: walletId);
});

// Provider takes (walletId, currentBalance) as a record
final _walletChartProvider =
    FutureProvider.family<List<_ChartPoint>, (int, double)>((ref, args) async {
  final (walletId, currentBalance) = args;
  final rows = await TransactionDao.instance.getFiltered(
    walletId: walletId,
    dateFrom: DateTime.now().subtract(const Duration(days: 29)),
  );

  final Map<String, double> netByDay = {};
  for (final tx in rows) {
    final key = tx.date.isoDate;
    netByDay[key] =
        (netByDay[key] ?? 0) + (tx.isIncome ? tx.amount : -tx.amount);
  }

  double running = currentBalance;
  final today = DateTime.now();
  final points = <_ChartPoint>[];

  for (var i = 0; i < 30; i++) {
    final date = today.subtract(Duration(days: i));
    points.add(_ChartPoint(date: date, balance: running));
    final key = date.isoDate;
    running -= (netByDay[key] ?? 0);
  }

  return points.reversed.toList();
});

class _ChartPoint {
  const _ChartPoint({required this.date, required this.balance});
  final DateTime date;
  final double balance;
}

// ─────────────────────────────────────────────
//  Main screen
// ─────────────────────────────────────────────
class WalletDetailScreen extends ConsumerWidget {
  const WalletDetailScreen({super.key, required this.wallet});
  final Wallet wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(_walletTxProvider(wallet.id!));
    final chartAsync =
        ref.watch(_walletChartProvider((wallet.id!, wallet.balance)));
    final rates = ref.watch(currencyRatesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(wallet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => WalletFormScreen(wallet: wallet),
                ),
              );
              if (updated == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Balance header ───────────────────
          _BalanceHeader(wallet: wallet, rates: rates),

          // ── Mini chart ───────────────────────
          chartAsync.when(
            loading: () => const SizedBox(height: 100),
            error: (_, __) => const SizedBox(height: 100),
            data: (points) => _MiniChart(
              points: points,
              currencyCode: wallet.currencyCode,
            ),
          ),

          const Divider(height: 1),

          // ── Transaction list ─────────────────
          Expanded(
            child: txAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (txs) => txs.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Sin movimientos',
                      subtitle: 'Esta billetera no tiene transacciones aún.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: txs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 68),
                      itemBuilder: (_, i) => _TxRow(
                        tx: txs[i],
                        rates: rates,
                        walletCurrency: wallet.currencyCode,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar billetera',
      message:
          '¿Eliminar "${wallet.name}"? Se borrarán también todas sus transacciones.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline,
    );
    if (confirmed && context.mounted) {
      await ref.read(walletsProvider.notifier).deleteWallet(wallet.id!);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

// ─────────────────────────────────────────────
//  Balance header
// ─────────────────────────────────────────────
class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.wallet, required this.rates});
  final Wallet wallet;
  final CurrencyRates rates;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final usdEquiv = rates.toUsd(wallet.balance, wallet.currencyCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(_iconDataForKey(wallet.icon),
                size: 22, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(wallet.name,
                        style: AppTextStyles.headingSmall
                            .copyWith(color: colorScheme.onSurface)),
                    const SizedBox(width: 8),
                    CurrencyBadge(currencyCode: wallet.currencyCode),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.byCurrency(wallet.balance, wallet.currencyCode),
                  style: AppTextStyles.amountMedium
                      .copyWith(color: colorScheme.onSurface),
                ),
                if (usdEquiv != null &&
                    wallet.currencyCode != CurrencyCodes.usd)
                  Text(
                    '≈ ${Formatters.usd(usdEquiv)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconDataForKey(String key) {
    const map = {
      'wallet': Icons.account_balance_wallet_outlined,
      'bank': Icons.account_balance_outlined,
      'cash': Icons.payments_outlined,
      'card': Icons.credit_card_outlined,
      'phone': Icons.smartphone_outlined,
      'savings': Icons.savings_outlined,
      'crypto': Icons.currency_bitcoin_outlined,
      'star': Icons.star_outline_rounded,
    };
    return map[key] ?? Icons.account_balance_wallet_outlined;
  }
}

// ─────────────────────────────────────────────
//  Mini chart — 30 day balance evolution
// ─────────────────────────────────────────────
class _MiniChart extends StatelessWidget {
  const _MiniChart({required this.points, required this.currencyCode});
  final List<_ChartPoint> points;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (points.length < 2) {
      return Container(
        height: 100,
        color: colorScheme.surfaceContainerLow,
        child: Center(
          child: Text(
            'Sin historial suficiente',
            style: AppTextStyles.caption
                .copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final minY = points.map((p) => p.balance).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.balance).reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs();
    final pad = range * 0.15;

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.balance);
    }).toList();

    // Determine trend color
    final first = points.first.balance;
    final last = points.last.balance;
    final trendColor =
        last >= first ? const Color(0xFF1D9E75) : colorScheme.error;

    return Container(
      height: 110,
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                Text(
                  'Últimos 30 días',
                  style: AppTextStyles.caption
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Icon(
                  last >= first
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 14,
                  color: trendColor,
                ),
                const SizedBox(width: 2),
                Text(
                  range > 0
                      ? '${last >= first ? '+' : ''}${Formatters.byCurrency((last - first).abs(), currencyCode)}'
                      : 'Sin cambios',
                  style: AppTextStyles.caption.copyWith(color: trendColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY - pad,
                maxY: maxY + pad,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: trendColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          trendColor.withOpacity(0.15),
                          trendColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) {
                      final idx = s.x.toInt();
                      final date =
                          idx < points.length ? points[idx].date : null;
                      return LineTooltipItem(
                        '${date != null ? '${date.day}/${date.month}\n' : ''}'
                        '${Formatters.byCurrency(s.y, currencyCode)}',
                        AppTextStyles.labelSmall.copyWith(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Transaction row
// ─────────────────────────────────────────────
class _TxRow extends StatelessWidget {
  const _TxRow({
    required this.tx,
    required this.rates,
    required this.walletCurrency,
  });
  final app_models.Transaction tx;
  final CurrencyRates rates;
  final String walletCurrency;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = tx.isIncome;
    final amountColor = isIncome ? const Color(0xFF1D9E75) : colorScheme.error;
    final sign = isIncome ? '+' : '−';
    final usd = walletCurrency != CurrencyCodes.usd
        ? (tx.rateSnapshot != null && tx.rateSnapshot! > 0
            ? tx.amount / tx.rateSnapshot!
            : rates.toUsd(tx.amount, walletCurrency))
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(tx.category?.icon ?? '📦',
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.category?.name ?? 'Sin categoría',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: colorScheme.onSurface)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    PaymentMethodBadge(method: tx.paymentMethod, compact: true),
                    const SizedBox(width: 6),
                    Text(Formatters.transactionDate(tx.date),
                        style: AppTextStyles.caption
                            .copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                if (tx.note != null && tx.note!.isNotEmpty)
                  Text(tx.note!,
                      style: AppTextStyles.caption
                          .copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${Formatters.byCurrency(tx.amount, walletCurrency)}',
                style: AppTextStyles.amountSmall.copyWith(color: amountColor),
              ),
              if (usd != null && walletCurrency != CurrencyCodes.usd)
                Text(
                    tx.rateSnapshot != null
                        ? '≈ ${Formatters.usd(usd)} hist.'
                        : '≈ ${Formatters.usd(usd)}',
                    style: AppTextStyles.caption
                        .copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
