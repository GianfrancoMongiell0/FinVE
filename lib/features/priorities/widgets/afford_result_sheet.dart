// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../priorities_provider.dart';

class AffordResultSheet extends StatelessWidget {
  const AffordResultSheet({
    super.key,
    required this.results,
    required this.totalBalanceUsd,
  });

  final List<AffordResult> results;
  final double totalBalanceUsd;

  static Future<void> show(
    BuildContext context, {
    required List<AffordResult> results,
    required double totalBalanceUsd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AffordResultSheet(
        results: results,
        totalBalanceUsd: totalBalanceUsd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canAffordCount = results.where((r) => r.canAfford).length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Column(
        children: [
          // ── Handle ──────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Column(
              children: [
                Text(
                  '¿Puedo pagarlo?',
                  style: AppTextStyles.headingMedium
                      .copyWith(color: colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Balance disponible: ${Formatters.usd(totalBalanceUsd)}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),

                // Summary pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SummaryPill(
                      label: '$canAffordCount puedes pagar',
                      color: const Color(0xFF1D9E75),
                      bgColor: const Color(0xFFE8F5E9),
                    ),
                    const SizedBox(width: 8),
                    _SummaryPill(
                      label:
                          '${results.length - canAffordCount} insuficiente',
                      color: const Color(0xFFF57F17),
                      bgColor: const Color(0xFFFFF3E0),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // ── Results list ─────────────────────
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      'Sin metas pendientes',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _ResultTile(result: results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Individual result tile ────────────────────
class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});
  final AffordResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final r = result;
    final p = r.priority;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: r.canAfford
            ? const Color(0xFFE8F5E9)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: r.canAfford
              ? const Color(0xFF1D9E75).withOpacity(0.3)
              : colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: r.canAfford
                  ? const Color(0xFF1D9E75)
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              r.canAfford
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              size: 18,
              color: r.canAfford
                  ? Colors.white
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(p.priorityLevel.emoji,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        p.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Target
                Text(
                  'Meta: ${Formatters.usd(r.targetUsd)}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),

                const SizedBox(height: 4),

                if (r.canAfford)
                  Text(
                    'Balance restante: ${Formatters.usd(r.balanceAfterUsd)}',
                    style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF1D9E75)),
                  )
                else
                  Text(
                    'Necesitas ${Formatters.usd(r.shortfallUsd)} más',
                    style: AppTextStyles.caption
                        .copyWith(color: const Color(0xFFF57F17)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary pill ──────────────────────────────
class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: color),
      ),
    );
  }
}
