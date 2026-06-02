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
              Text(
                summary.currentNet >= 0 ? 'Superávit' : 'Déficit',
                style: AppTextStyles.labelMedium.copyWith(
                  color: summary.currentNet >= 0
                      ? const Color(0xFF1D9E75)
                      : colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Income
              Expanded(
                child: _SummaryTile(
                  label: 'Ingresos',
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFF1D9E75),
                  bgColor: const Color(0xFFE8F5E9),
                  amount: summary.currentIncome,
                  change: summary.incomeChange,
                  previousAmount: summary.previousIncome,
                ),
              ),
              const SizedBox(width: 10),
              // Expense
              Expanded(
                child: _SummaryTile(
                  label: 'Gastos',
                  icon: Icons.arrow_upward_rounded,
                  iconColor: colorScheme.error,
                  bgColor: colorScheme.errorContainer.withOpacity(0.3),
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
    required this.amount,
    required this.change,
    required this.previousAmount,
    this.invertChange = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final double amount;
  final double change;
  final double previousAmount;
  final bool invertChange;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // For expenses: increase is bad (red), decrease is good (green)
    // For income: increase is good (green), decrease is bad (red)
    final isPositiveChange = invertChange ? change <= 0 : change >= 0;
    final changeColor =
        isPositiveChange ? const Color(0xFF1D9E75) : colorScheme.error;
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
                  style: AppTextStyles.labelMedium
                      .copyWith(color: colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.usd(amount),
            style: AppTextStyles.amountMedium
                .copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          if (previousAmount > 0) ...[
            Row(
              children: [
                Icon(changeIcon, size: 12, color: changeColor),
                const SizedBox(width: 3),
                Text(
                  '${change.abs().toStringAsFixed(0)}% vs mes anterior',
                  style: AppTextStyles.caption
                      .copyWith(color: changeColor),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Sin datos del mes anterior',
              style: AppTextStyles.caption
                  .copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
