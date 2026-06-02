import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/budget.dart';
import '../../core/models/category.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/extensions.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import 'budget_provider.dart';
import 'widgets/budget_card.dart';

const _monthNames = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre'
];

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(budgetProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto'),
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
        data: (state) => Column(
          children: [
            // Month navigator
            _MonthNavigator(
              month: state.month,
              year: state.year,
              onPrev: () {
                final prev = DateTime(state.year, state.month - 1);
                ref
                    .read(budgetProvider.notifier)
                    .setMonth(prev.month, prev.year);
              },
              onNext: () {
                final now = DateTime.now();
                final next = DateTime(state.year, state.month + 1);
                if (next.isBefore(DateTime(now.year, now.month + 1))) {
                  ref
                      .read(budgetProvider.notifier)
                      .setMonth(next.month, next.year);
                }
              },
            ),

            // Summary bar
            if (state.budgets.isNotEmpty) _SummaryBar(state: state),

            const Divider(height: 1),

            // Budget list
            Expanded(
              child: state.budgets.isEmpty
                  ? EmptyState(
                      icon: Icons.pie_chart_outline_rounded,
                      title: 'Sin presupuestos',
                      subtitle:
                          'Crea límites de gasto por categoría para controlar tus finanzas.',
                      actionLabel: 'Crear presupuesto',
                      onAction: () => _showForm(context, ref, state, null),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      itemCount: state.budgets.length,
                      itemBuilder: (_, i) {
                        final b = state.budgets[i];
                        return BudgetCard(
                          budget: b,
                          onEdit: () => _showForm(context, ref, state, b),
                          onDelete: () => _confirmDelete(context, ref, b),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: stateAsync.valueOrNull != null
          ? FloatingActionButton(
              heroTag: 'budget_fab',
              onPressed: () => _showForm(context, ref, stateAsync.value!, null),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  Future<void> _showForm(BuildContext context, WidgetRef ref, BudgetState state,
      Budget? budget) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _BudgetForm(
          budget: budget,
          state: state,
          onSaved: (b) => ref.read(budgetProvider.notifier).saveBudget(b),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Budget b) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar presupuesto',
      message: '¿Eliminar el presupuesto de "${b.category?.name}"?',
    );
    if (confirmed) {
      ref.read(budgetProvider.notifier).deleteBudget(b.id!);
    }
  }
}

// ── Month navigator ───────────────────────────
class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.year,
    required this.onPrev,
    required this.onNext,
  });

  final int month;
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isCurrentMonth = month == now.month && year == now.year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrev,
          ),
          Expanded(
            child: Text(
              '${_monthNames[month - 1]} $year',
              textAlign: TextAlign.center,
              style: AppTextStyles.headingSmall
                  .copyWith(color: colorScheme.onSurface),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded,
                color: isCurrentMonth ? colorScheme.outlineVariant : null),
            onPressed: isCurrentMonth ? null : onNext,
          ),
        ],
      ),
    );
  }
}

// ── Summary bar ───────────────────────────────
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.state});
  final BudgetState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pct = state.totalBudgeted > 0
        ? (state.totalSpent / state.totalBudgeted).clamp(0.0, 1.0)
        : 0.0;
    final color = state.overBudget.isNotEmpty
        ? colorScheme.error
        : state.warning.isNotEmpty
            ? const Color(0xFFD97706)
            : const Color(0xFF1D9E75);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gasto total del mes',
                  style: AppTextStyles.caption
                      .copyWith(color: colorScheme.onSurfaceVariant)),
              Text(
                '\$${state.totalSpent.toStringAsFixed(0)} / \$${state.totalBudgeted.toStringAsFixed(0)}',
                style: AppTextStyles.labelMedium
                    .copyWith(color: colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          if (state.overBudget.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '⚠️ ${state.overBudget.length} categoría(s) excedida(s)',
              style: AppTextStyles.caption.copyWith(color: colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Budget form ───────────────────────────────
class _BudgetForm extends StatefulWidget {
  const _BudgetForm({
    this.budget,
    required this.state,
    required this.onSaved,
  });

  final Budget? budget;
  final BudgetState state;
  final Future<void> Function(Budget) onSaved;

  @override
  State<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<_BudgetForm> {
  late TextEditingController _amountCtrl;
  Category? _selectedCategory;
  String _currency = CurrencyCodes.usd;
  bool _saving = false;
  late List<Category> _availableCategories;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.budget != null ? widget.budget!.amount.toString() : '',
    );
    if (widget.budget != null) {
      _selectedCategory = widget.state.categories.firstWhere(
        (c) => c.id == widget.budget!.categoryId,
        orElse: () => widget.state.categories.first,
      );
      _currency = widget.budget!.currencyCode;
    }

    // Pre-compute available categories once in initState, not on every build
    final budgetedIds = widget.state.budgets
        .where((b) => b.id != widget.budget?.id)
        .map((b) => b.categoryId)
        .toSet();
    _availableCategories = widget.state.categories
        .where((c) => !budgetedIds.contains(c.id))
        .toList();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedCategory == null) {
      context.showSnackBar('Selecciona una categoría', isError: true);
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      context.showSnackBar('Ingresa un monto válido', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final budget = Budget(
        id: widget.budget?.id,
        categoryId: _selectedCategory!.id!,
        amount: amount,
        currencyCode: _currency,
        month: widget.state.month,
        year: widget.state.year,
        createdAt: widget.budget?.createdAt ?? DateTime.now(),
      );
      await widget.onSaved(budget);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = widget.budget != null;

    return Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Editar presupuesto' : 'Nuevo presupuesto'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // Category selector — chips avoid expensive dropdown overlay
              Text('Categoría',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              if (isEdit && _selectedCategory != null)
                _ChipItem(
                  category: _selectedCategory!,
                  selected: true,
                  onTap: null,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableCategories.map((c) {
                    final sel = _selectedCategory?.id == c.id;
                    return _ChipItem(
                      category: c,
                      selected: sel,
                      onTap: () => setState(() => _selectedCategory = c),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 12),

              // Amount + currency
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Límite mensual',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Moneda',
                            style: AppTextStyles.caption
                                .copyWith(color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: CurrencyCodes.all.map((c) {
                            final sel = _currency == c;
                            return GestureDetector(
                              onTap: () => setState(() => _currency = c),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: sel
                                      ? Border.all(
                                          color: colorScheme.primary,
                                          width: 1.5)
                                      : null,
                                ),
                                child: Text(
                                  '${CurrencyCodes.flag(c)} $c',
                                  style: AppTextStyles.caption.copyWith(
                                    color: sel
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurface,
                                    fontWeight:
                                        sel ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isEdit ? 'Actualizar' : 'Crear presupuesto'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ));
  }
}

class _ChipItem extends StatelessWidget {
  const _ChipItem({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final dynamic category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: AppTextStyles.labelMedium.copyWith(
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
