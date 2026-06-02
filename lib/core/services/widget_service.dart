import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../database/daos/wallet_dao.dart';
import '../database/daos/transaction_dao.dart';
import '../models/currency_rates.dart';

import '../utils/formatters.dart';

class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  static const String _appGroupId = 'com.finve.app';
  static const String _androidWidgetName = 'HomeWidgetProvider';

  // ─────────────────────────────────────────────
  //  Main update — call on app launch + after tx
  // ─────────────────────────────────────────────
  Future<void> updateAllWidgets(CurrencyRates rates) async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      final walletDao = WalletDao.instance;
      final txDao = TransactionDao.instance;

      final wallets = await walletDao.getAll();
      final recentTx = await txDao.getRecent(3);

      // ── Compute totals ───────────────────────
      double totalUsd = 0;
      for (final w in wallets) {
        totalUsd += rates.toUsd(w.balance, w.currencyCode) ?? 0;
      }

      // ── Write widget data ────────────────────

      // Small widget
      await HomeWidget.saveWidgetData<String>(
        'widget_total_usd',
        Formatters.usd(totalUsd),
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_last_updated',
        Formatters.timeAgo(rates.fetchedAt),
      );

      // Medium widget — wallet list (up to 4)
      for (var i = 0; i < 4; i++) {
        if (i < wallets.length) {
          final w = wallets[i];
          final usd = rates.toUsd(w.balance, w.currencyCode) ?? 0;
          await HomeWidget.saveWidgetData<String>(
            'wallet_${i}_name', w.name);
          await HomeWidget.saveWidgetData<String>(
            'wallet_${i}_balance',
            Formatters.byCurrency(w.balance, w.currencyCode));
          await HomeWidget.saveWidgetData<String>(
            'wallet_${i}_usd', Formatters.usd(usd));
          await HomeWidget.saveWidgetData<String>(
            'wallet_${i}_currency', w.currencyCode);
        } else {
          await HomeWidget.saveWidgetData<String>(
              'wallet_${i}_name', '');
        }
      }
      await HomeWidget.saveWidgetData<int>(
          'wallet_count', wallets.length);

      // Large widget — rate strip
      await HomeWidget.saveWidgetData<String>(
        'widget_bcv_rate',
        rates.bcvRate > 0
            ? Formatters.rate(rates.bcvRate)
            : '—',
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_parallel_rate',
        rates.parallelRate > 0
            ? Formatters.rate(rates.parallelRate)
            : '—',
      );

      // Large widget — last 3 transactions
      for (var i = 0; i < 3; i++) {
        if (i < recentTx.length) {
          final tx = recentTx[i];
          final sign = tx.isIncome ? '+' : '−';
          await HomeWidget.saveWidgetData<String>(
            'tx_${i}_icon', tx.category?.icon ?? '📦');
          await HomeWidget.saveWidgetData<String>(
            'tx_${i}_amount',
            '$sign${Formatters.usd(tx.amount)}');
          await HomeWidget.saveWidgetData<String>(
            'tx_${i}_category',
            tx.category?.name ?? 'Sin categoría');
        } else {
          await HomeWidget.saveWidgetData<String>('tx_${i}_icon', '');
        }
      }

      // ── Trigger widget refresh ───────────────
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
      );

      debugPrint('[WidgetService] Widgets updated, totalUsd=$totalUsd');
    } catch (e) {
      debugPrint('[WidgetService] Update error: $e');
    }
  }
}
