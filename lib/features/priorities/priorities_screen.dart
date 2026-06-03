// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/priority.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/formatters.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import 'priorities_provider.dart';
import 'priority_form_screen.dart';
import 'widgets/afford_result_sheet.dart';
import 'widgets/priority_item_card.dart';

class PrioritiesScreen extends ConsumerWidget {
  const PrioritiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(prioritiesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          final allEmpty = state.pending.isEmpty && state.completed.isEmpty;

          if (allEmpty) {
            return EmptyState(
              icon: Icons.flag_outlined,
              illustration: EmptyIllustration.goals,
              title: 'Sin metas aún',
              subtitle:
                  'Define tus objetivos financieros y rastrea tu progreso.',
              actionLabel: 'Nueva meta',
              onAction: () => _openForm(context),
            );
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  // ── Balance summary ──────────
                  _BalanceSummary(totalUsd: state.totalBalanceUsd),
                  const SizedBox(height: 16),

                  // ── HIGH ─────────────────────
                  if (state.highPriority.isNotEmpty) ...[
                    _GroupHeader(
                        level: PriorityLevel.high,
                        count: state.highPriority.length),
                    const SizedBox(height: 8),
                    ...state.highPriority.map((p) => PriorityItemCard(
                          priority: p,
                          state: state,
                          onTap: () => _openForm(context, priority: p),
                          onToggleCompleted: () => ref
                              .read(prioritiesProvider.notifier)
                              .toggleCompleted(p),
                          onDelete: () => _confirmDelete(context, ref, p),
                        )),
                    const SizedBox(height: 8),
                  ],

                  // ── MEDIUM ───────────────────
                  if (state.mediumPriority.isNotEmpty) ...[
                    _GroupHeader(
                        level: PriorityLevel.medium,
                        count: state.mediumPriority.length),
                    const SizedBox(height: 8),
                    ...state.mediumPriority.map((p) => PriorityItemCard(
                          priority: p,
                          state: state,
                          onTap: () => _openForm(context, priority: p),
                          onToggleCompleted: () => ref
                              .read(prioritiesProvider.notifier)
                              .toggleCompleted(p),
                          onDelete: () => _confirmDelete(context, ref, p),
                        )),
                    const SizedBox(height: 8),
                  ],

                  // ── LOW ──────────────────────
                  if (state.lowPriority.isNotEmpty) ...[
                    _GroupHeader(
                        level: PriorityLevel.low,
                        count: state.lowPriority.length),
                    const SizedBox(height: 8),
                    ...state.lowPriority.map((p) => PriorityItemCard(
                          priority: p,
                          state: state,
                          onTap: () => _openForm(context, priority: p),
                          onToggleCompleted: () => ref
                              .read(prioritiesProvider.notifier)
                              .toggleCompleted(p),
                          onDelete: () => _confirmDelete(context, ref, p),
                        )),
                    const SizedBox(height: 8),
                  ],

                  // ── DONE ─────────────────────
                  if (state.completed.isNotEmpty) ...[
                    const Divider(height: 32),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: Color(0xFF1D9E75)),
                        const SizedBox(width: 8),
                        Text(
                          'Completadas (${state.completed.length})',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: const Color(0xFF1D9E75)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...state.completed.map(
                      (p) => _CompletedTile(
                        priority: p,
                        onUndo: () => ref
                            .read(prioritiesProvider.notifier)
                            .toggleCompleted(p),
                        onDelete: () => _confirmDelete(context, ref, p),
                      ),
                    ),
                  ],
                ],
              ),

              // ── "Can I afford it?" FAB ───────
              if (state.pending.isNotEmpty)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: FilledButton.icon(
                    onPressed: () => _showAffordSheet(context, ref, state),
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('¿Puedo pagarlo?'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'priorities_fab',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _openForm(BuildContext context, {Priority? priority}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PriorityFormScreen(priority: priority),
      ),
    );
  }

  void _showAffordSheet(
      BuildContext context, WidgetRef ref, PrioritiesState state) {
    final results =
        ref.read(prioritiesProvider.notifier).computeAffordability(state);
    AffordResultSheet.show(
      context,
      results: results,
      totalBalanceUsd: state.totalBalanceUsd,
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Priority p) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar meta',
      message: '¿Eliminar "${p.name}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline,
    );
    if (confirmed) {
      await ref.read(prioritiesProvider.notifier).delete(p.id!);
    }
  }
}

// ── Balance summary card ──────────────────────
class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({required this.totalUsd});
  final double totalUsd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: colorScheme.primary.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            'Balance disponible',
            style:
                AppTextStyles.labelLarge.copyWith(color: colorScheme.onSurface),
          ),
          const Spacer(),
          Text(
            Formatters.usd(totalUsd),
            style:
                AppTextStyles.amountMedium.copyWith(color: colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

// ── Group header ──────────────────────────────
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.level, required this.count});
  final PriorityLevel level;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(level.emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(
          '${level.label} · $count',
          style: AppTextStyles.labelLarge
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }
}

// ── Completed tile ────────────────────────────
class _CompletedTile extends StatelessWidget {
  const _CompletedTile({
    required this.priority,
    required this.onUndo,
    required this.onDelete,
  });

  final Priority priority;
  final VoidCallback onUndo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading:
            const Icon(Icons.check_circle_rounded, color: Color(0xFF1D9E75)),
        title: Text(
          priority.name,
          style: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          Formatters.byCurrency(priority.targetAmount, priority.currencyCode),
          style: AppTextStyles.caption
              .copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'undo') onUndo();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'undo',
              child: Row(children: [
                Icon(Icons.undo_rounded, size: 18),
                SizedBox(width: 10),
                Text('Marcar pendiente'),
              ]),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                const SizedBox(width: 10),
                Text('Eliminar', style: TextStyle(color: colorScheme.error)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
