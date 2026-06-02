import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/daos/recurring_expense_dao.dart';
import '../../../core/database/daos/category_dao.dart';
import '../../../core/models/recurring_expense.dart';
import '../../../core/models/category.dart';
import '../../../core/models/wallet.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../wallets/wallets_provider.dart';

final _recurringProvider =
    FutureProvider<List<RecurringExpense>>((ref) async {
  return RecurringExpenseDao.instance.getAll();
});

class RecurringSettingsScreen extends ConsumerWidget {
  const RecurringSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(_recurringProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos recurrentes')),
      body: listAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.event_repeat_rounded,
                title: 'Sin gastos recurrentes',
                subtitle:
                    'Programa gastos fijos como servicios, suscripciones, etc.',
                actionLabel: 'Agregar',
                onAction: () => _openForm(context, ref, null),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (_, i) => _RecurringCard(
                  expense: items[i],
                  onEdit: () => _openForm(context, ref, items[i]),
                  onDelete: () =>
                      _confirmDelete(context, ref, items[i]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'recurring_fab',
        onPressed: () => _openForm(context, ref, null),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      RecurringExpense? expense) async {
    final wallets =
        ref.read(walletsProvider).valueOrNull?.wallets ?? [];
    if (wallets.isEmpty && context.mounted) {
      context.showSnackBar(
          'Crea una billetera antes de agregar gastos recurrentes',
          isError: true);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecurringFormScreen(
          expense: expense,
          wallets: wallets,
          onSaved: () => ref.invalidate(_recurringProvider),
        ),
      ),
    );
    ref.invalidate(_recurringProvider);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      RecurringExpense expense) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar gasto recurrente',
      message: '¿Eliminar "${expense.name}"?',
    );
    if (confirmed) {
      await RecurringExpenseDao.instance.delete(expense.id!);
      ref.invalidate(_recurringProvider);
    }
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });
  final RecurringExpense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(expense.category?.icon ?? '📦',
                style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(expense.name, style: AppTextStyles.bodyMedium),
        subtitle: Text(
          '${Formatters.byCurrency(expense.amount, expense.currencyCode)} '
          '· Día ${expense.dayOfMonth} '
          '· ${expense.autoRegister ? 'Auto' : 'Manual'}',
          style: AppTextStyles.caption
              .copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: PopupMenuButton<String>(
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
                ])),
            PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline,
                      size: 18, color: colorScheme.error),
                  const SizedBox(width: 10),
                  Text('Eliminar',
                      style: TextStyle(color: colorScheme.error)),
                ])),
          ],
        ),
      ),
    );
  }
}

// ── Recurring expense form ────────────────────
class RecurringFormScreen extends ConsumerStatefulWidget {
  const RecurringFormScreen({
    super.key,
    this.expense,
    required this.wallets,
    required this.onSaved,
  });
  final RecurringExpense? expense;
  final List<Wallet> wallets;
  final VoidCallback onSaved;

  @override
  ConsumerState<RecurringFormScreen> createState() =>
      _RecurringFormScreenState();
}

class _RecurringFormScreenState
    extends ConsumerState<RecurringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late String _currency;
  late Wallet? _wallet;
  int? _categoryId;
  late PaymentMethod _paymentMethod;
  late int _dayOfMonth;
  late bool _autoRegister;
  bool _saving = false;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountCtrl = TextEditingController(
        text: e != null ? e.amount.toString() : '');
    _currency = e?.currencyCode ?? CurrencyCodes.usd;
    _wallet = e != null
        ? widget.wallets
            .firstWhere((w) => w.id == e.walletId,
                orElse: () => widget.wallets.first)
        : widget.wallets.first;
    _categoryId = e?.categoryId;
    _paymentMethod = e?.paymentMethod ?? PaymentMethod.cash;
    _dayOfMonth = e?.dayOfMonth ?? 1;
    _autoRegister = e?.autoRegister ?? false;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryDao.instance.getAll();
    if (mounted) setState(() => _categories = cats);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_wallet == null) return;
    setState(() => _saving = true);
    try {
      final expense = RecurringExpense(
        id: widget.expense?.id,
        name: _nameCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
        currencyCode: _currency,
        walletId: _wallet!.id!,
        categoryId: _categoryId,
        paymentMethod: _paymentMethod,
        dayOfMonth: _dayOfMonth,
        autoRegister: _autoRegister,
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
      );
      if (widget.expense != null) {
        await RecurringExpenseDao.instance.update(expense);
      } else {
        await RecurringExpenseDao.instance.insert(expense);
      }
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense != null
            ? 'Editar gasto recurrente'
            : 'Nuevo gasto recurrente'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text('Guardar',
                style: AppTextStyles.labelLarge
                    .copyWith(color: colorScheme.primary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.event_repeat_rounded)),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Monto',
                        prefixIcon: Icon(Icons.attach_money_rounded)),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Obligatorio';
                      if (double.tryParse(v.replaceAll(',', '.')) == null) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration:
                        const InputDecoration(labelText: 'Moneda'),
                    items: CurrencyCodes.all
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${CurrencyCodes.flag(c)} $c')))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _currency = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Wallet>(
              value: _wallet,
              decoration: const InputDecoration(
                  labelText: 'Billetera',
                  prefixIcon: Icon(
                      Icons.account_balance_wallet_outlined)),
              items: widget.wallets
                  .map((w) => DropdownMenuItem(
                      value: w, child: Text(w.name)))
                  .toList(),
              onChanged: (w) => setState(() => _wallet = w),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _categoryId,
              decoration: const InputDecoration(
                  labelText: 'Categoría (opcional)'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Sin categoría')),
                ..._categories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.icon}  ${c.name}'))),
              ],
              onChanged: (v) =>
                  setState(() => _categoryId = v),
            ),
            const SizedBox(height: 12),
            // Day of month slider
            Row(
              children: [
                Text('Día del mes: $_dayOfMonth',
                    style: AppTextStyles.bodyMedium),
                Expanded(
                  child: Slider(
                    value: _dayOfMonth.toDouble(),
                    min: 1,
                    max: 31,
                    divisions: 30,
                    label: '$_dayOfMonth',
                    onChanged: (v) =>
                        setState(() => _dayOfMonth = v.round()),
                  ),
                ),
              ],
            ),
            // Payment method
            Wrap(
              spacing: 8,
              children: PaymentMethod.values.map((p) {
                final sel = _paymentMethod == p;
                return ChoiceChip(
                  selected: sel,
                  label: Text('${p.emoji} ${p.label}'),
                  onSelected: (_) =>
                      setState(() => _paymentMethod = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Auto-registrar'),
              subtitle: const Text(
                  'Registra la transacción automáticamente en la fecha indicada'),
              value: _autoRegister,
              onChanged: (v) =>
                  setState(() => _autoRegister = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(widget.expense != null
                  ? 'Actualizar'
                  : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
