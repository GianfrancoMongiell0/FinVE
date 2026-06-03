// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/theme/app_colors.dart';
import '../dashboard_provider.dart';

class MonthlySummaryCard extends StatelessWidget {
  const MonthlySummaryCard({super.key, required this.summary});
  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ingresos — verde fijo de la paleta (accent de OceanBlue)
    final incomeBg = isDark
        ? OceanBlueColors.accent800.withOpacity(0.35)
        : OceanBlueColors.accent50;
    const incomeFg = OceanBlueColors.accent600;
    const incomeIcon = OceanBlueColors.accent400;

    // Gastos — rojo fijo de la paleta
    final expenseBg = isDark
        ? RoseNightColors.primary800.withOpacity(0.35)
        : RoseNightColors.primary50;
    const expenseFg = RoseNightColors.primary600;
    const expenseIcon = RoseNightColors.primary400;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: summary.currentNet >= 0
                      ? OceanBlueColors.accent50
                      : RoseNightColors.primary50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  summary.currentNet >= 0 ? 'Superávit' : 'Déficit',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: summary.currentNet >= 0
                        ? OceanBlueColors.accent600
                        : RoseNightColors.primary600,
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
                  iconColor: incomeIcon,
                  bgColor: incomeBg,
                  fgColor: incomeFg,
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
                  iconColor: expenseIcon,
                  bgColor: expenseBg,
                  fgColor: expenseFg,
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
    final isPositiveChange = invertChange ? change <= 0 : change >= 0;
    final changeColor = isPositiveChange
        ? OceanBlueColors.accent600
        : RoseNightColors.primary600;
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
        border: Border.all(
          color: fgColor.withOpacity(0.15),
          width: 0.5,
        ),
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
                      .copyWith(color: fgColor.withOpacity(0.8))),
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
                  .copyWith(color: fgColor.withOpacity(0.5)),
            ),
          ],
        ],
      ),
    );
  }
}