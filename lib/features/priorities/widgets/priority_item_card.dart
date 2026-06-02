import 'package:flutter/material.dart';
import '../../../core/models/priority.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../priorities_provider.dart';

class PriorityItemCard extends StatelessWidget {
  const PriorityItemCard({
    super.key,
    required this.priority,
    required this.state,
    required this.onTap,
    required this.onToggleCompleted,
    required this.onDelete,
  });

  final Priority priority;
  final PrioritiesState state;
  final VoidCallback onTap;
  final VoidCallback onToggleCompleted;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final p = priority;
    final targetUsd = state.targetUsd(p);
    final progress = state.progressFor(p);
    final canAfford = state.canAfford(p);
    final shortfall = state.shortfall(p);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority level badge
                  _PriorityBadge(level: p.priorityLevel),
                  const SizedBox(width: 10),

                  // Name + notes
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: AppTextStyles.headingSmall
                              .copyWith(color: colorScheme.onSurface),
                        ),
                        if (p.notes != null && p.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              p.notes!,
                              style: AppTextStyles.caption.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Context menu
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (v) {
                      if (v == 'edit') onTap();
                      if (v == 'complete') onToggleCompleted();
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
                        value: 'complete',
                        child: Row(children: [
                          Icon(
                            p.isCompleted
                                ? Icons.undo_rounded
                                : Icons.check_circle_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(p.isCompleted
                              ? 'Marcar pendiente'
                              : 'Marcar completado'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline,
                              size: 18,
                              color: colorScheme.error),
                          const SizedBox(width: 10),
                          Text('Eliminar',
                              style:
                                  TextStyle(color: colorScheme.error)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Amount row ─────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.byCurrency(
                              p.targetAmount, p.currencyCode),
                          style: AppTextStyles.amountMedium
                              .copyWith(color: colorScheme.onSurface),
                        ),
                        if (p.currencyCode != CurrencyCodes.usd)
                          Text(
                            '≈ ${Formatters.usd(targetUsd)}',
                            style: AppTextStyles.caption.copyWith(
                                color: colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  // Afford status badge
                  _AffordBadge(
                      canAfford: canAfford, shortfallUsd: shortfall),
                ],
              ),

              const SizedBox(height: 10),

              // ── Progress bar ───────────────────
              _ProgressBar(progress: progress, canAfford: canAfford),

              const SizedBox(height: 6),

              // ── Progress label ─────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance actual: ${Formatters.usd(state.totalBalanceUsd)}',
                    style: AppTextStyles.caption
                        .copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.caption.copyWith(
                      color: canAfford
                          ? const Color(0xFF1D9E75)
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Priority level badge ──────────────────────
class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.level});
  final PriorityLevel level;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (level) {
      PriorityLevel.high => (
          const Color(0xFFFFE5E5),
          const Color(0xFFD32F2F)
        ),
      PriorityLevel.medium => (
          const Color(0xFFFFF8E1),
          const Color(0xFFF57F17)
        ),
      PriorityLevel.low => (
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32)
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(level.emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            level.label,
            style: AppTextStyles.labelSmall.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

// ── Afford badge ──────────────────────────────
class _AffordBadge extends StatelessWidget {
  const _AffordBadge(
      {required this.canAfford, required this.shortfallUsd});
  final bool canAfford;
  final double shortfallUsd;

  @override
  Widget build(BuildContext context) {
    if (canAfford) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 13, color: Color(0xFF2E7D32)),
            const SizedBox(width: 4),
            Text(
              'Puedes pagarlo',
              style: AppTextStyles.labelSmall
                  .copyWith(color: const Color(0xFF2E7D32)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_outlined,
              size: 13, color: Color(0xFFF57F17)),
          const SizedBox(width: 4),
          Text(
            'Faltan ${Formatters.usd(shortfallUsd)}',
            style: AppTextStyles.labelSmall
                .copyWith(color: const Color(0xFFF57F17)),
          ),
        ],
      ),
    );
  }
}

// ── Progress bar ──────────────────────────────
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.canAfford});
  final double progress;
  final bool canAfford;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fillColor = canAfford
        ? const Color(0xFF1D9E75)
        : colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        backgroundColor: colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(fillColor),
      ),
    );
  }
}
