// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../budget/budget_provider.dart';

class BudgetSummaryCard extends ConsumerWidget {
  const BudgetSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return budgetAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        if (state.budgets.isEmpty) return const SizedBox.shrink();

        final atRisk = [
          ...state.overBudget,
          ...state.warning,
        ].take(3).toList();

        if (atRisk.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
          onTap: () => Navigator.of(context).pushNamed('/budget'),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Presupuesto',
                    style: AppTextStyles.headingSmall
                        .copyWith(color: colorScheme.onSurface),
                  ),
                  const Spacer(),
                  Text(
                    '${state.overBudget.length + state.warning.length} en riesgo',
                    style: AppTextStyles.caption.copyWith(
                        color: colorScheme.error),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 16, color: colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 10),
              ...atRisk.map((b) {
                final color = b.isOverBudget
                    ? colorScheme.error
                    : const Color(0xFFD97706);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(b.category?.icon ?? '📦',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  b.category?.name ??
                                      'Sin categoría',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(
                                          color:
                                              colorScheme.onSurface),
                                ),
                                Text(
                                  b.isOverBudget
                                      ? '+${Formatters.usd(b.spent - b.amount)}'
                                      : '${Formatters.usd(b.remaining)} restante',
                                  style:
                                      AppTextStyles.caption.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: b.percentage,
                                backgroundColor:
                                    color.withOpacity(0.12),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        color),
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            ),
          ),
        );
      },
    );
  }
}
