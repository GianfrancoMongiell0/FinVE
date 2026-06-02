import 'package:flutter/material.dart';
import '../../../core/models/transaction.dart' as app_models;
import '../../../core/models/currency_rates.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/payment_method_badge.dart';

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.walletCurrency,
    required this.rates,
    this.onTap,
    this.onDelete,
  });

  final app_models.Transaction transaction;
  final String walletCurrency;
  final CurrencyRates rates;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tx = transaction;
    final isIncome = tx.isIncome;
    final amountColor =
        isIncome ? const Color(0xFF1D9E75) : colorScheme.error;
    final sign = isIncome ? '+' : '−';

    final usdEquiv = walletCurrency != CurrencyCodes.usd
        ? rates.toUsd(tx.amount, walletCurrency)
        : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Category icon ──────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  tx.category?.icon ?? '📦',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Category + meta ────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.category?.name ?? 'Sin categoría',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      PaymentMethodBadge(
                          method: tx.paymentMethod, compact: true),
                      const SizedBox(width: 6),
                      Text(
                        Formatters.transactionDate(tx.date),
                        style: AppTextStyles.caption.copyWith(
                            color: colorScheme.onSurfaceVariant),
                      ),
                      if (tx.wallet != null) ...[
                        const SizedBox(width: 6),
                        const Text('·',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 10)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            tx.wallet!.name,
                            style: AppTextStyles.caption.copyWith(
                                color: colorScheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (tx.note != null && tx.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        tx.note!,
                        style: AppTextStyles.caption.copyWith(
                            color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Amount ─────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$sign${Formatters.byCurrency(tx.amount, walletCurrency)}',
                  style:
                      AppTextStyles.amountSmall.copyWith(color: amountColor),
                ),
                if (usdEquiv != null)
                  Text(
                    '≈ ${Formatters.usd(usdEquiv)}',
                    style: AppTextStyles.caption.copyWith(
                        color: colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
