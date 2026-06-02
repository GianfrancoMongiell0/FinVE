import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/transaction.dart' as app_models;
import '../../core/utils/extensions.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../wallets/wallets_provider.dart';
import 'transaction_form_screen.dart';
import 'transactions_provider.dart';
import 'widgets/filter_bar.dart';
import 'widgets/transaction_list_item.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(transactionsProvider);
    final walletsState = ref.watch(walletsProvider).valueOrNull;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar en notas…',
                  border: InputBorder.none,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant),
                ),
                onChanged: (v) {
                  ref.read(transactionsProvider.notifier).setFilter(
                        stateAsync.valueOrNull?.filter
                                .copyWith(searchNote: v) ??
                            TransactionFilter(searchNote: v),
                      );
                },
              )
            : const Text('Movimientos'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchCtrl.clear();
                ref.read(transactionsProvider.notifier).setFilter(
                      stateAsync.valueOrNull?.filter
                              .copyWith(clearSearch: true) ??
                          TransactionFilter.empty,
                    );
              }
            },
          ),
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
            const SizedBox(height: 8),
            FilterBar(
              filter: state.filter,
              categories: state.categories,
              wallets: walletsState?.wallets ?? [],
              onChanged: (f) =>
                  ref.read(transactionsProvider.notifier).setFilter(f),
              onClear: () =>
                  ref.read(transactionsProvider.notifier).clearFilter(),
            ),
            const SizedBox(height: 8),
            if (state.filter.isActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '${state.transactions.length} resultado(s)',
                      style: AppTextStyles.caption.copyWith(
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: state.transactions.isEmpty
                  ? EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: state.filter.isActive
                          ? 'Sin resultados'
                          : 'Sin movimientos aún',
                      subtitle: state.filter.isActive
                          ? 'Intenta con otros filtros.'
                          : 'Registra tu primer ingreso o gasto.',
                      actionLabel:
                          state.filter.isActive ? null : 'Nuevo movimiento',
                      onAction: state.filter.isActive
                          ? null
                          : () => _openForm(context),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: state.transactions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (_, i) {
                        final tx = state.transactions[i];
                        final walletCurrency = walletsState?.wallets
                                .where((w) => w.id == tx.walletId)
                                .firstOrNull
                                ?.currencyCode ??
                            'USD';
                        return Dismissible(
                          key: ValueKey(tx.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: colorScheme.error,
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white),
                          ),
                          confirmDismiss: (_) => ConfirmDialog.show(
                            context,
                            title: 'Eliminar movimiento',
                            message:
                                '¿Eliminar este movimiento? Se ajustará el balance de la billetera.',
                            confirmLabel: 'Eliminar',
                          ),
                          onDismissed: (_) async {
                            try {
                              await ref
                                  .read(transactionsProvider.notifier)
                                  .deleteTransaction(tx);
                              if (context.mounted) {
                                context.showSnackBar('Movimiento eliminado');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                context.showSnackBar(
                                    'Error al eliminar: $e', isError: true);
                              }
                            }
                          },
                          child: TransactionListItem(
                            transaction: tx,
                            walletCurrency: walletCurrency,
                            rates: state.rates,
                            onTap: () => _openForm(context, transaction: tx),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'transactions_fab',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _openForm(BuildContext context,
      {app_models.Transaction? transaction}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(transaction: transaction),
      ),
    );
  }
}
