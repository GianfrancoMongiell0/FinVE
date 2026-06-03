// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../../shared/mixins/unsaved_changes_mixin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/wallet.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/extensions.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/save_button.dart';
import 'wallets_provider.dart';

// Available wallet icons
const _kIcons = [
  ('wallet', Icons.account_balance_wallet_outlined),
  ('bank', Icons.account_balance_outlined),
  ('cash', Icons.payments_outlined),
  ('card', Icons.credit_card_outlined),
  ('phone', Icons.smartphone_outlined),
  ('savings', Icons.savings_outlined),
  ('crypto', Icons.currency_bitcoin_outlined),
  ('star', Icons.star_outline_rounded),
];

IconData _iconData(String key) =>
    _kIcons.firstWhere((e) => e.$1 == key, orElse: () => _kIcons.first).$2;

class WalletFormScreen extends ConsumerStatefulWidget {
  const WalletFormScreen({super.key, this.wallet});

  /// If null → add mode; if set → edit mode.
  final Wallet? wallet;

  @override
  ConsumerState<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends ConsumerState<WalletFormScreen>
    with UnsavedChangesMixin<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _balanceCtrl;
  late String _selectedCurrency;
  late String _selectedIcon;
  bool _isDirty = false;

  @override
  bool get hasUnsavedChanges => _isDirty;

  bool get _isEditing => widget.wallet != null;

  @override
  void initState() {
    super.initState();
    final w = widget.wallet;
    _nameCtrl = TextEditingController(text: w?.name ?? '');
    _balanceCtrl = TextEditingController(
        text: w != null && w.balance > 0 ? w.balance.toString() : '');
    _selectedCurrency = w?.currencyCode ?? CurrencyCodes.usd;
    _selectedIcon = w?.icon ?? 'wallet';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      throw Exception('validation');
    }

    try {
      final balance =
          double.tryParse(_balanceCtrl.text.replaceAll(',', '.')) ?? 0.0;

      if (_isEditing) {
        final updated = widget.wallet!.copyWith(
          name: _nameCtrl.text.trim(),
          currencyCode: _selectedCurrency,
          balance: balance,
          icon: _selectedIcon,
        );
        await ref.read(walletsProvider.notifier).updateWallet(updated);
      } else {
        final wallet = Wallet(
          name: _nameCtrl.text.trim(),
          currencyCode: _selectedCurrency,
          balance: balance,
          icon: _selectedIcon,
          createdAt: DateTime.now(),
        );
        await ref.read(walletsProvider.notifier).addWallet(wallet);
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canLeave = await confirmDiscard(context);
        if (canLeave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar billetera' : 'Nueva billetera'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Icon picker ────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconData(_selectedIcon),
                        size: 36,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Elige un ícono',
                        style: AppTextStyles.caption
                            .copyWith(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _kIcons.map((entry) {
                        final selected = _selectedIcon == entry.$1;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedIcon = entry.$1;
                            _isDirty = true;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(
                                      color: colorScheme.primary, width: 2)
                                  : null,
                            ),
                            child: Icon(entry.$2,
                                size: 22,
                                color: selected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Name ───────────────────────────
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la billetera',
                  hintText: 'Ej: Efectivo, Zelle, BTC personal…',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() => _isDirty = true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  if (v.trim().length > 40) {
                    return 'Máximo 40 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Currency ───────────────────────
              _SectionLabel('Moneda'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CurrencyCodes.all.map((code) {
                  final selected = _selectedCurrency == code;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCurrency = code),
                    label: Text('${CurrencyCodes.flag(code)}  $code'),
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                    selectedColor: colorScheme.primaryContainer,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    side: selected
                        ? BorderSide(color: colorScheme.primary)
                        : BorderSide(color: colorScheme.outlineVariant),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ── Initial balance ────────────────
              TextFormField(
                controller: _balanceCtrl,
                decoration: InputDecoration(
                  labelText: _isEditing ? 'Balance actual' : 'Balance inicial',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                  suffixText: _selectedCurrency,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: false),
                onChanged: (_) => setState(() => _isDirty = true),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null) return 'Ingresa un número válido';
                  if (parsed < 0) return 'El balance no puede ser negativo';
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // ── Save button ────────────────────
              SaveButton(
                label: _isEditing ? 'Actualizar billetera' : 'Crear billetera',
                onSave: _save,
              ),
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