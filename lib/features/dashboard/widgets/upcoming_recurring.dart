// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../../../core/models/recurring_expense.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_text_styles.dart';

class UpcomingRecurring extends StatelessWidget {
  const UpcomingRecurring({
    super.key,
    required this.expenses,
    required this.onManage,
  });

  final List<RecurringExpense> expenses;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.tertiary.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
              child: Row(
                children: [
                  Icon(Icons.event_repeat_rounded,
                      size: 16, color: colorScheme.tertiary),
                  const SizedBox(width: 6),
                  Text(
                    'Próximos esta semana',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: colorScheme.onSurface),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onManage,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Gestionar',
                      style: AppTextStyles.caption
                          .copyWith(color: colorScheme.tertiary),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // List
            ...expenses.take(4).map((e) => _ExpenseRow(expense: e)),

            if (expenses.length > 4)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                child: Text(
                  '+${expenses.length - 4} más esta semana',
                  style: AppTextStyles.caption
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});
  final RecurringExpense expense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final days = expense.daysUntilDue;
    final dueText = days == 0
        ? 'Hoy'
        : days == 1
            ? 'Mañana'
            : 'En $days días';

    final dueColor = days == 0
        ? colorScheme.error
        : days == 1
            ? colorScheme.tertiary
            : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Category icon
          Text(
            expense.category?.icon ?? '📦',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 10),

          // Name + wallet
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  expense.wallet?.name ?? 'Billetera',
                  style: AppTextStyles.caption
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Amount + due date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.byCurrency(expense.amount, expense.currencyCode),
                style: AppTextStyles.amountSmall
                    .copyWith(color: colorScheme.onSurface),
              ),
              Text(
                dueText,
                style: AppTextStyles.caption.copyWith(color: dueColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
