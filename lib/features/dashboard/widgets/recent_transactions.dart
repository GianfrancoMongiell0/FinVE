// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../../../core/models/transaction.dart' as app_models;
import '../../../core/models/currency_rates.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/payment_method_badge.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({
    super.key,
    required this.transactions,
    required this.rates,
    required this.onViewAll,
    required this.onTap,
  });

  final List<app_models.Transaction> transactions;
  final CurrencyRates rates;
  final VoidCallback onViewAll;
  final ValueChanged<app_models.Transaction> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
          child: Row(
            children: [
              Text(
                'Últimos movimientos',
                style: AppTextStyles.headingSmall
                    .copyWith(color: colorScheme.onSurface),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'Ver todos',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        if (transactions.isEmpty)
          _EmptyState()
        else ...[
          ...transactions.map(
            (tx) => _TransactionTile(
              transaction: tx,
              rates: rates,
              onTap: () => onTap(tx),
            ),
          ),
          // Hint that rows are tappable
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'Toca un movimiento para editarlo',
              style: AppTextStyles.caption.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
            ),
          ),
        ],
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.rates,
    required this.onTap,
  });

  final app_models.Transaction transaction;
  final CurrencyRates rates;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tx = transaction;
    final isIncome = tx.isIncome;
    final amountColor =
        isIncome ? const Color(0xFF1D9E75) : colorScheme.error;
    final sign = isIncome ? '+' : '−';
    final usdEquiv = rates.toUsd(tx.amount, 'USD');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  tx.category?.icon ?? '📦',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Name + meta
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
                  const SizedBox(height: 2),
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
                    ],
                  ),
                  if (tx.note != null && tx.note!.isNotEmpty)
                    Text(
                      tx.note!,
                      style: AppTextStyles.caption.copyWith(
                          color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Amount + edit icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${Formatters.usd(tx.amount)}',
                  style: AppTextStyles.amountSmall
                      .copyWith(color: amountColor),
                ),
                if (usdEquiv != null && usdEquiv != tx.amount)
                  Text(
                    Formatters.usd(usdEquiv),
                    style: AppTextStyles.caption.copyWith(
                        color: colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(height: 2),
                Icon(
                  Icons.edit_outlined,
                  size: 12,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                color: colorScheme.outlineVariant, size: 32),
            const SizedBox(height: 8),
            Text(
              'Sin movimientos aún',
              style: AppTextStyles.bodySmall
                  .copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
