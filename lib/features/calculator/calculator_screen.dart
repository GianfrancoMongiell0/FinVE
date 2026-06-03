// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/rate_provider.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/formatters.dart';
import '../../shared/theme/app_text_styles.dart';
import '../transactions/transaction_form_screen.dart';
import 'calculator_provider.dart';

class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar tasas',
            onPressed: () =>
                ref.read(rateProvider.notifier).forceRefresh(),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all_rounded),
            tooltip: 'Limpiar',
            onPressed: () =>
                ref.read(calculatorProvider.notifier).clear(),
          ),
        ],
      ),
      body: const _CalculatorBody(),
    );
  }
}

// ── Body (stateful for text controllers) ─────
class _CalculatorBody extends ConsumerStatefulWidget {
  const _CalculatorBody();

  @override
  ConsumerState<_CalculatorBody> createState() => _CalculatorBodyState();
}

class _CalculatorBodyState extends ConsumerState<_CalculatorBody> {
  // One controller per field
  final Map<String, TextEditingController> _controllers = {
    for (final f in CalculatorState.allFields)
      f: TextEditingController(),
  };
  // Track which field is being edited to avoid feedback loops
  String? _activeField;

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  void _onChanged(String field, String raw) {
    _activeField = field;
    ref.read(calculatorProvider.notifier).onFieldChanged(field, raw);
  }

  void _syncControllers(CalculatorState state) {
    for (final field in CalculatorState.allFields) {
      if (field == _activeField) continue; // don't overwrite typing field
      final ctrl = _controllers[field]!;
      final display = state.displayFor(field);
      if (ctrl.text != display) {
        ctrl.value = TextEditingValue(
          text: display,
          selection: TextSelection.collapsed(offset: display.length),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calcState = ref.watch(calculatorProvider);
    final lastUpdated = ref.watch(ratesLastUpdatedProvider);
    final isOffline = ref.watch(ratesOfflineProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Sync non-active fields whenever state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllers(calcState);
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Rate status strip ──────────────────
        _RateStatusBar(
            lastUpdated: lastUpdated, isOffline: isOffline),
        const SizedBox(height: 16),

        // ── Currency fields ────────────────────
        _CurrencyField(
          field: CurrencyCodes.usd,
          label: 'Dólar estadounidense',
          flag: '🇺🇸',
          sublabel: 'USD',
          controller: _controllers[CurrencyCodes.usd]!,
          isActive: _activeField == CurrencyCodes.usd,
          onChanged: (v) => _onChanged(CurrencyCodes.usd, v),
          onTap: () => setState(() => _activeField = CurrencyCodes.usd),
        ),

        const _Divider(),

        _CurrencyField(
          field: 'VES_BCV',
          label: 'Bolívar (tasa BCV)',
          flag: '🇻🇪',
          sublabel: calcState.rates.bcvRate > 0
              ? 'BCV: ${Formatters.rate(calcState.rates.bcvRate)}'
              : 'BCV no disponible',
          controller: _controllers['VES_BCV']!,
          isActive: _activeField == 'VES_BCV',
          isUnavailable: calcState.rates.bcvRate <= 0,
          onChanged: (v) => _onChanged('VES_BCV', v),
          onTap: () => setState(() => _activeField = 'VES_BCV'),
        ),

        const _Divider(),

        _CurrencyField(
          field: 'VES_PARALLEL',
          label: 'Bolívar (paralelo)',
          flag: '🇻🇪',
          sublabel: calcState.rates.parallelRate > 0
              ? 'Paralelo: ${Formatters.rate(calcState.rates.parallelRate)}'
              : 'Tasa paralela no disponible',
          controller: _controllers['VES_PARALLEL']!,
          isActive: _activeField == 'VES_PARALLEL',
          isUnavailable: calcState.rates.parallelRate <= 0,
          onChanged: (v) => _onChanged('VES_PARALLEL', v),
          onTap: () => setState(() => _activeField = 'VES_PARALLEL'),
        ),

        const _Divider(),

        _CurrencyField(
          field: CurrencyCodes.btc,
          label: 'Bitcoin',
          flag: '🟠',
          sublabel: calcState.rates.btcUsd > 0
              ? '\$${Formatters.compactUsd(calcState.rates.btcUsd)} / BTC'
              : 'BTC no disponible',
          controller: _controllers[CurrencyCodes.btc]!,
          isActive: _activeField == CurrencyCodes.btc,
          isUnavailable: calcState.rates.btcUsd <= 0,
          isCrypto: true,
          onChanged: (v) => _onChanged(CurrencyCodes.btc, v),
          onTap: () => setState(() => _activeField = CurrencyCodes.btc),
        ),

        const _Divider(),

        _CurrencyField(
          field: CurrencyCodes.eth,
          label: 'Ethereum',
          flag: '🔷',
          sublabel: calcState.rates.ethUsd > 0
              ? '\$${Formatters.compactUsd(calcState.rates.ethUsd)} / ETH'
              : 'ETH no disponible',
          controller: _controllers[CurrencyCodes.eth]!,
          isActive: _activeField == CurrencyCodes.eth,
          isUnavailable: calcState.rates.ethUsd <= 0,
          isCrypto: true,
          onChanged: (v) => _onChanged(CurrencyCodes.eth, v),
          onTap: () => setState(() => _activeField = CurrencyCodes.eth),
        ),

        const _Divider(),

        _CurrencyField(
          field: CurrencyCodes.sol,
          label: 'Solana',
          flag: '🟣',
          sublabel: calcState.rates.solUsd > 0
              ? '\$${Formatters.compactUsd(calcState.rates.solUsd)} / SOL'
              : 'SOL no disponible',
          controller: _controllers[CurrencyCodes.sol]!,
          isActive: _activeField == CurrencyCodes.sol,
          isUnavailable: calcState.rates.solUsd <= 0,
          isCrypto: true,
          onChanged: (v) => _onChanged(CurrencyCodes.sol, v),
          onTap: () => setState(() => _activeField = CurrencyCodes.sol),
        ),

        const SizedBox(height: 24),

        // ── "Use this amount" button ───────────
        if (_activeField != null && calcState.values[_activeField] != null)
          _UseAmountButton(
            field: _activeField!,
            state: calcState,
          ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Individual currency field ─────────────────
class _CurrencyField extends StatelessWidget {
  const _CurrencyField({
    required this.field,
    required this.label,
    required this.flag,
    required this.sublabel,
    required this.controller,
    required this.isActive,
    required this.onChanged,
    required this.onTap,
    this.isUnavailable = false,
    this.isCrypto = false,
  });

  final String field;
  final String label;
  final String flag;
  final String sublabel;
  final TextEditingController controller;
  final bool isActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;
  final bool isUnavailable;
  final bool isCrypto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isActive
            ? Border.all(color: colorScheme.primary, width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Flag / icon
          Text(flag, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),

          // Labels
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isUnavailable
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                  ),
                ),
                Text(
                  sublabel,
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Amount input
          Expanded(
            flex: 3,
            child: isUnavailable
                ? Text(
                    'N/D',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.amountMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : TextField(
                    controller: controller,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d.,]')),
                    ],
                    style: AppTextStyles.amountMedium.copyWith(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: AppTextStyles.amountMedium.copyWith(
                        color: colorScheme.outlineVariant,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: onChanged,
                    onTap: onTap,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── "Use this amount" button ──────────────────
class _UseAmountButton extends ConsumerWidget {
  const _UseAmountButton({required this.field, required this.state});

  final String field;
  final CalculatorState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final amount = state.values[field];
    if (amount == null) return const SizedBox.shrink();

    // Map internal field key to actual currency code
    final currency = switch (field) {
      'VES_BCV' || 'VES_PARALLEL' => CurrencyCodes.ves,
      _ => field,
    };

    final displayAmount = state.displayFor(field);
    final currencySymbol = CurrencyCodes.symbol(currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TransactionFormScreen(
                  prefilledAmount: amount,
                  prefilledCurrency: currency,
                ),
                fullscreenDialog: true,
              ),
            );
          },
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: Text(
              'Usar $currencySymbol$displayAmount como monto'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}

// ── Rate status bar ───────────────────────────
class _RateStatusBar extends StatelessWidget {
  const _RateStatusBar({
    required this.lastUpdated,
    required this.isOffline,
  });

  final String lastUpdated;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color =
        isOffline ? colorScheme.error : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isOffline
                ? Icons.cloud_off_outlined
                : Icons.sync_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            isOffline
                ? 'Sin conexión — tasas guardadas'
                : 'Tasas actualizadas $lastUpdated',
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ── Divider between fields ────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 56,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

// ─────────────────────────────────────────────
//  Modal bottom sheet version (for global FAB)
// ─────────────────────────────────────────────
Future<void> showCalculatorSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Calculadora',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: _CalculatorBody()),
        ],
      ),
    ),
  );
}
