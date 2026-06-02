import 'package:flutter/material.dart';
import '../../../core/models/budget.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_text_styles.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.budget,
    required this.onEdit,
    required this.onDelete,
  });

  final Budget budget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _statusColor(colorScheme);
    final cat = budget.category;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      cat?.icon ?? '📦',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat?.name ?? 'Sin categoría',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: colorScheme.onSurface),
                      ),
                      Text(
                        '${Formatters.usd(budget.spent)} de ${Formatters.usd(budget.amount)}',
                        style: AppTextStyles.caption.copyWith(
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Status badge
                _StatusBadge(budget: budget, color: color),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Editar'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: colorScheme.error),
                        const SizedBox(width: 10),
                        Text('Eliminar',
                            style: TextStyle(color: colorScheme.error)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: budget.percentage,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 6),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  budget.isOverBudget
                      ? '⚠️ Excediste por ${Formatters.usd(budget.spent - budget.amount)}'
                      : 'Quedan ${Formatters.usd(budget.remaining)}',
                  style: AppTextStyles.caption.copyWith(color: color),
                ),
                Text(
                  '${(budget.percentage * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.caption
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ColorScheme cs) {
    if (budget.isOverBudget) return cs.error;
    if (budget.isWarning) return const Color(0xFFD97706);
    return const Color(0xFF1D9E75);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.budget, required this.color});
  final Budget budget;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = budget.isOverBudget
        ? 'Excedido'
        : budget.isWarning
            ? 'Cerca'
            : 'OK';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}
