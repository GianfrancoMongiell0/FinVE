import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../dashboard_provider.dart';

class MonthlySummaryCard extends StatelessWidget {
  const MonthlySummaryCard({super.key, required this.summary});
  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Resumen de ${summary.monthName}',
                  style: AppTextStyles.headingSmall
                      .copyWith(color: colorScheme.onSurface)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: summary.currentNet >= 0
                      ? colorScheme.tertiaryContainer
                      : colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  summary.currentNet >= 0 ? 'Superávit' : 'Déficit',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: summary.currentNet >= 0
                        ? colorScheme.onTertiaryContainer
                        : colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Ingresos',
                  icon: Icons.arrow_downward_rounded,
                  iconColor: colorScheme.tertiary,
                  bgColor: colorScheme.tertiaryContainer,
                  fgColor: colorScheme.onTertiaryContainer,
                  amount: summary.currentIncome,
                  change: summary.incomeChange,
                  previousAmount: summary.previousIncome,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Gastos',
                  icon: Icons.arrow_upward_rounded,
                  iconColor: colorScheme.error,
                  bgColor: colorScheme.errorContainer,
                  fgColor: colorScheme.onErrorContainer,
                  amount: summary.currentExpense,
                  change: summary.expenseChange,
                  previousAmount: summary.previousExpense,
                  invertChange: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.fgColor,
    required this.amount,
    required this.change,
    required this.previousAmount,
    this.invertChange = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color fgColor;
  final double amount;
  final double change;
  final double previousAmount;
  final bool invertChange;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isPositiveChange = invertChange ? change <= 0 : change >= 0;
    final changeColor =
        isPositiveChange ? colorScheme.tertiary : colorScheme.error;
    final changeIcon = change > 0
        ? Icons.trending_up_rounded
        : change < 0
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(label,
                  style: AppTextStyles.labelMedium.copyWith(color: fgColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.usd(amount),
            style: AppTextStyles.amountMedium.copyWith(color: fgColor),
          ),
          const SizedBox(height: 4),
          if (previousAmount > 0) ...[
            Row(
              children: [
                Icon(changeIcon, size: 12, color: changeColor),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    '${change.abs().toStringAsFixed(0)}% vs mes anterior',
                    style: AppTextStyles.caption.copyWith(color: changeColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Sin datos anteriores',
              style: AppTextStyles.caption
                  .copyWith(color: fgColor.withOpacity(0.6)),
            ),
          ],
        ],
      ),
    );
  }
}
