// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rate_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_text_styles.dart';

class RateStrip extends ConsumerWidget {
  const RateStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rateState = ref.watch(rateProvider).valueOrNull;
    final rates = rateState?.rates;
    final lastUpdated = ref.watch(ratesLastUpdatedProvider);
    final isOffline = ref.watch(ratesOfflineProvider);
    final isStale = ref.watch(ratesStaleProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Warning banner
        if (isOffline || isStale)
          _WarningBanner(
            isOffline: isOffline,
            onRefresh: () => ref.read(rateProvider.notifier).forceRefresh(),
          ),

        // Rate strip
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // BCV
              Expanded(
                child: _RateTile(
                  label: 'BCV',
                  value: rates != null && rates.bcvRate > 0
                      ? Formatters.rate(rates.bcvRate)
                      : '—',
                  color: colorScheme.primary,
                ),
              ),

              // Divider
              Container(
                width: 1,
                height: 28,
                color: colorScheme.outlineVariant,
              ),

              // Parallel
              Expanded(
                child: _RateTile(
                  label: 'Paralelo',
                  value: rates != null && rates.parallelRate > 0
                      ? Formatters.rate(rates.parallelRate)
                      : '—',
                  color: const Color(0xFF1D9E75),
                ),
              ),

              // Divider
              Container(
                width: 1,
                height: 28,
                color: colorScheme.outlineVariant,
              ),

              // Last updated
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      isOffline
                          ? Icons.cloud_off_outlined
                          : isStale
                              ? Icons.schedule_outlined
                              : Icons.check_circle_outline,
                      size: 13,
                      color: isOffline
                          ? colorScheme.error
                          : isStale
                              ? colorScheme.tertiary
                              : const Color(0xFF1D9E75),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastUpdated,
                      style: AppTextStyles.caption.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RateTile extends StatelessWidget {
  const _RateTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.amountSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.isOffline,
    required this.onRefresh,
  });

  final bool isOffline;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isOffline ? colorScheme.error : colorScheme.tertiary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.wifi_off_rounded : Icons.access_time_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline
                  ? 'Sin conexión — mostrando tasas guardadas'
                  : 'Tasas desactualizadas — toca para refrescar',
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ),
          GestureDetector(
            onTap: onRefresh,
            child: Icon(Icons.refresh_rounded, size: 16, color: color),
          ),
        ],
      ),
    );
  }
}
