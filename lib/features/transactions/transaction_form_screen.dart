// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../../shared/mixins/unsaved_changes_mixin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/daos/category_dao.dart';
import '../../core/models/transaction.dart' as app_models;
import '../../core/models/category.dart';
import '../../core/models/wallet.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/formatters.dart';
import '../../core/providers/rate_provider.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/save_button.dart';
import '../wallets/wallets_provider.dart';
import 'transactions_provider.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    super.key,
    this.transaction,
    this.prefilledAmount,
    this.prefilledCurrency,
    this.prefilledWalletId,
  });

  /// If non-null → edit mode.
  final app_models.Transaction? transaction;

  /// Pre-filled values from Calculator screen (Phase 11).
  final double? prefilledAmount;
  final String? prefilledCurrency;
  final int? prefilledWalletId;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen>
    with UnsavedChangesMixin<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;

  TransactionType _type = TransactionType.expense;
  Wallet? _selectedWallet;
  Category? _selectedCategory;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  late DateTime _date;
  bool _isDirty = false;
  List<Category> _categories = [];

  @override
  bool get hasUnsavedChanges => _isDirty;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountCtrl = TextEditingController(
        text: tx != null
            ? tx.amount.toString()
            : widget.prefilledAmount?.toString() ?? '');
    _noteCtrl = TextEditingController(text: tx?.note ?? '');
    _type = tx?.type ?? TransactionType.expense;
    _paymentMethod = tx?.paymentMethod ?? PaymentMethod.cash;
    _date = tx?.date ?? DateTime.now();
    _loadCategories();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryDao.instance.getAll();
    if (mounted) {
      setState(() {
        _categories = cats;
        if (widget.transaction?.categoryId != null) {
          _selectedCategory = cats.firstWhere(
              (c) => c.id == widget.transaction!.categoryId,
              orElse: () => cats.first);
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) throw Exception('validation');
    if (_selectedWallet == null) {
      context.showSnackBar('Selecciona una billetera', isError: true);
      throw Exception('no_wallet');
    }

    try {
      final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));

      // Capturar la tasa BCV del momento solo para transacciones en VES.
      // Esto permite calcular el valor histórico en USD aunque la tasa cambie.
      final rates = ref.read(currencyRatesProvider);
      final rateSnapshot = _selectedWallet!.currencyCode == CurrencyCodes.ves
          ? (rates.bcvRate > 0 ? rates.bcvRate : null)
          : null;

      final tx = app_models.Transaction(
        id: widget.transaction?.id,
        walletId: _selectedWallet!.id!,
        amount: amount,
        type: _type,
        categoryId: _selectedCategory?.id,
        paymentMethod: _paymentMethod,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        date: _date,
        createdAt: widget.transaction?.createdAt ?? DateTime.now(),
        rateSnapshot: rateSnapshot,
      );

      if (_isEditing) {
        await ref
            .read(transactionsProvider.notifier)
            .updateTransaction(widget.transaction!, tx);
      } else {
        await ref.read(transactionsProvider.notifier).addTransaction(tx);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) context.showSnackBar('Error al guardar: $e', isError: true);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final walletsAsync = ref.watch(walletsProvider);
    final wallets = walletsAsync.valueOrNull?.wallets ?? [];

    // Auto-select wallet on first load
    if (_selectedWallet == null && wallets.isNotEmpty) {
      final prefId = widget.transaction?.walletId ?? widget.prefilledWalletId;
      if (prefId != null) {
        _selectedWallet = wallets.firstWhere((w) => w.id == prefId,
            orElse: () => wallets.first);
      } else if (widget.prefilledCurrency != null) {
        // Prefer wallet matching the currency from calculator
        _selectedWallet = wallets.firstWhere(
            (w) => w.currencyCode == widget.prefilledCurrency,
            orElse: () => wallets.first);
      } else {
        _selectedWallet = wallets.first;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canLeave = await confirmDiscard(context);
        if (canLeave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar movimiento' : 'Nuevo movimiento'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Type toggle ────────────────────
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: TransactionType.values.map((t) {
                    final selected = _type == t;
                    final isIncome = t == TransactionType.income;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = t;
                          _selectedCategory = null;
                          _isDirty = true;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? (isIncome
                                    ? const Color(0xFF1D9E75)
                                    : colorScheme.error)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isIncome
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                size: 16,
                                color: selected
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                t.label,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // ── Amount ─────────────────────────
              TextFormField(
                controller: _amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Monto',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  suffixText: _selectedWallet?.currencyCode ?? '',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: !_isEditing,
                style: AppTextStyles.amountMedium,
                onChanged: (_) => setState(() => _isDirty = true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa un monto';
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null) return 'Número inválido';
                  if (parsed <= 0) return 'El monto debe ser mayor a 0';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Wallet selector ────────────────
              _SectionLabel('Billetera'),
              const SizedBox(height: 8),
              if (wallets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Crea una billetera primero',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: colorScheme.error),
                  ),
                )
              else
                DropdownButtonFormField<Wallet>(
                  value: _selectedWallet,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  items: wallets
                      .map((w) => DropdownMenuItem(
                            value: w,
                            child: Row(
                              children: [
                                Text(w.name),
                                const SizedBox(width: 8),
                                Text(
                                  Formatters.byCurrency(
                                      w.balance, w.currencyCode),
                                  style: AppTextStyles.caption.copyWith(
                                      color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (w) => setState(() => _selectedWallet = w),
                ),

              const SizedBox(height: 16),

              // ── Category ───────────────────────
              _SectionLabel('Categoría'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories
                    .where((c) => _type == TransactionType.income
                        ? c.isIncome
                        : c.isExpense)
                    .map((c) {
                  final selected = _selectedCategory?.id == c.id;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedCategory = c;
                      _isDirty = true;
                    }),
                    avatar: Text(c.icon, style: const TextStyle(fontSize: 14)),
                    label: Text(c.name),
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                    selectedColor: colorScheme.primaryContainer,
                    side: selected
                        ? BorderSide(color: colorScheme.primary)
                        : BorderSide(color: colorScheme.outlineVariant),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ── Payment method ─────────────────
              _SectionLabel('Método de pago'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PaymentMethod.values.map((p) {
                  final selected = _paymentMethod == p;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _paymentMethod = p;
                      _isDirty = true;
                    }),
                    avatar: Text(p.emoji, style: const TextStyle(fontSize: 14)),
                    label: Text(p.label),
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                    selectedColor: colorScheme.primaryContainer,
                    side: selected
                        ? BorderSide(color: colorScheme.primary)
                        : BorderSide(color: colorScheme.outlineVariant),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ── Date picker ────────────────────
              _SectionLabel('Fecha'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: colorScheme.outlineVariant, width: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 20, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(
                        Formatters.fullDate(_date),
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: colorScheme.onSurface),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Note ───────────────────────────
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  hintText: 'Agrega un detalle…',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
                maxLength: 200,
                onChanged: (_) => setState(() => _isDirty = true),
              ),

              const SizedBox(height: 24),

              // ── Save button ────────────────────
              SaveButton(
                label: _isEditing
                    ? 'Actualizar movimiento'
                    : 'Registrar movimiento',
                onSave: _save,
                color: _type == TransactionType.income
                    ? const Color(0xFF1D9E75)
                    : colorScheme.error,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelLarge
          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
