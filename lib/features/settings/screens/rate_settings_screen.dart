import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rate_provider.dart';
import '../../../core/services/rate_service.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_text_styles.dart';

class RateSettingsScreen extends ConsumerWidget {
  const RateSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rateState = ref.watch(rateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasas de cambio'),
        actions: [
          IconButton(
            icon: rateState.valueOrNull?.isLoading == true
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(rateProvider.notifier).forceRefresh(),
            tooltip: 'Actualizar tasas',
          ),
        ],
      ),
      body: rateState.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Status card ──────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: state.isOffline
                    ? colorScheme.errorContainer.withOpacity(0.3)
                    : colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    state.isOffline
                        ? Icons.cloud_off_outlined
                        : Icons.check_circle_outline,
                    color: state.isOffline
                        ? colorScheme.error
                        : const Color(0xFF1D9E75),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.isOffline
                          ? 'Sin conexión — mostrando tasas guardadas'
                          : 'Última actualización: ${ref.watch(ratesLastUpdatedProvider)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Fiat rates ───────────────────
            _SectionLabel('Tasas BCV / Paralelo'),
            const SizedBox(height: 8),
            _RateTile(
              pair: RatePairs.bcv,
              label: 'Tasa BCV oficial',
              flag: '🇻🇪',
              value: state.rates.bcvRate,
              sublabel: 'Bs / USD',
              ref: ref,
              hasOverride: ref
                  .read(rateProvider.notifier)
                  .hasManualOverride(RatePairs.bcv),
            ),
            _RateTile(
              pair: RatePairs.parallel,
              label: 'Tasa paralela',
              flag: '🇻🇪',
              value: state.rates.parallelRate,
              sublabel: 'Bs / USD',
              ref: ref,
              hasOverride: ref
                  .read(rateProvider.notifier)
                  .hasManualOverride(RatePairs.parallel),
            ),

            const SizedBox(height: 16),
            _SectionLabel('Precios crypto (USD)'),
            const SizedBox(height: 8),
            _RateTile(
              pair: RatePairs.btc,
              label: 'Bitcoin',
              flag: '🟠',
              value: state.rates.btcUsd,
              sublabel: 'USD / BTC',
              ref: ref,
              hasOverride: ref
                  .read(rateProvider.notifier)
                  .hasManualOverride(RatePairs.btc),
            ),
            _RateTile(
              pair: RatePairs.eth,
              label: 'Ethereum',
              flag: '🔷',
              value: state.rates.ethUsd,
              sublabel: 'USD / ETH',
              ref: ref,
              hasOverride: ref
                  .read(rateProvider.notifier)
                  .hasManualOverride(RatePairs.eth),
            ),
            _RateTile(
              pair: RatePairs.sol,
              label: 'Solana',
              flag: '🟣',
              value: state.rates.solUsd,
              sublabel: 'USD / SOL',
              ref: ref,
              hasOverride: ref
                  .read(rateProvider.notifier)
                  .hasManualOverride(RatePairs.sol),
            ),

            if (state.rates.isManualOverride) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  ref
                      .read(rateProvider.notifier)
                      .clearAllManualOverrides();
                  context.showSnackBar(
                      'Tasas manuales eliminadas');
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar todos los valores manuales'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RateTile extends ConsumerWidget {
  const _RateTile({
    required this.pair,
    required this.label,
    required this.flag,
    required this.value,
    required this.sublabel,
    required this.ref,
    required this.hasOverride,
  });

  final String pair;
  final String label;
  final String flag;
  final double value;
  final String sublabel;
  final WidgetRef ref;
  final bool hasOverride;

  @override
  Widget build(BuildContext context, WidgetRef wRef) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(flag, style: const TextStyle(fontSize: 22)),
        title: Text(label, style: AppTextStyles.bodyMedium),
        subtitle: Text(
          value > 0
              ? '${value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2)} $sublabel'
              : 'No disponible',
          style: AppTextStyles.caption
              .copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasOverride)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Manual',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: colorScheme.onTertiaryContainer)),
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _showOverrideDialog(context, wRef),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOverrideDialog(
      BuildContext context, WidgetRef wRef) async {
    final ctrl = TextEditingController(
        text: value > 0 ? value.toString() : '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Establecer $label manualmente'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Valor en $sublabel',
            hintText: '0.00',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed == true && ctrl.text.isNotEmpty) {
      final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
      if (v != null && v > 0) {
        wRef.read(rateProvider.notifier).setManualOverride(pair, v);
        if (context.mounted) {
          context.showSnackBar('Tasa manual guardada');
        }
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(
          color: Theme.of(context).colorScheme.primary),
    );
  }
}
