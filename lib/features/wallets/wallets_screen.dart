import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/formatters.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/currency_badge.dart';
import '../../shared/widgets/empty_state.dart';
import 'wallet_detail_screen.dart';
import 'wallet_form_screen.dart';
import '../../core/providers/balance_visibility_provider.dart';
import 'wallets_provider.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(walletsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billeteras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: stateAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          if (state.wallets.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Sin billeteras aún',
              subtitle:
                  'Crea tu primera billetera para comenzar a registrar tus finanzas.',
              actionLabel: 'Nueva billetera',
              onAction: () => _openForm(context, ref),
            );
          }

          return Column(
            children: [
              // ── Total header ─────────────────
              _TotalHeader(totalUsd: state.totalUsd, visible: ref.watch(balanceVisibleProvider)),

              // ── Wallet list ──────────────────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: state.wallets.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final w = state.wallets[i];
                    final usd = state.usdEquivalent(w);
                    return _WalletCard(
                      wallet: w,
                      usdEquivalent: usd,
                      visible: ref.watch(balanceVisibleProvider),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WalletDetailScreen(wallet: w),
                        ),
                      ),
                      onEdit: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WalletFormScreen(wallet: w),
                        ),
                      ),
                      onDelete: () =>
                          _confirmDelete(context, ref, w.id!, w.name),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'wallets_fab',
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WalletFormScreen()),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      int id, String name) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar billetera',
      message: 'Eliminar "$name" también borrará todas sus transacciones. '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline,
    );
    if (confirmed) {
      await ref.read(walletsProvider.notifier).deleteWallet(id);
    }
  }
}

// ── Total header ──────────────────────────────
class _TotalHeader extends StatelessWidget {
  const _TotalHeader({required this.totalUsd, required this.visible});
  final double totalUsd;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
              color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance total',
            style: AppTextStyles.labelMedium
                .copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            visible ? Formatters.usd(totalUsd) : '••••••',
            style: AppTextStyles.amountLarge
                .copyWith(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

// ── Wallet card ───────────────────────────────
class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.wallet,
    required this.usdEquivalent,
    required this.visible,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final wallet;
  final double usdEquivalent;
  final bool visible;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _iconMap = {
    'wallet': Icons.account_balance_wallet_outlined,
    'bank': Icons.account_balance_outlined,
    'cash': Icons.payments_outlined,
    'card': Icons.credit_card_outlined,
    'phone': Icons.smartphone_outlined,
    'savings': Icons.savings_outlined,
    'crypto': Icons.currency_bitcoin_outlined,
    'star': Icons.star_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon =
        _iconMap[wallet.icon] ?? Icons.account_balance_wallet_outlined;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 24, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),

              // Name + currency
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name,
                      style: AppTextStyles.headingSmall
                          .copyWith(color: colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    CurrencyBadge(currencyCode: wallet.currencyCode),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Balance + USD equiv
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    visible
                        ? Formatters.byCurrency(wallet.balance, wallet.currencyCode)
                        : '••••••',
                    style: AppTextStyles.amountMedium
                        .copyWith(color: colorScheme.onSurface),
                  ),
                  if (wallet.currencyCode != CurrencyCodes.usd)
                    Text(
                      visible ? Formatters.usd(usdEquivalent) : '••••',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
              const SizedBox(width: 4),

              // Context menu
              PopupMenuButton<String>(
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
                          style: TextStyle(color: colorScheme.error)),
                    ]),
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
