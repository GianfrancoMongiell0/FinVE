import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/category.dart';
import '../../../core/models/wallet.dart';
import '../../../core/utils/constants.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../transactions_provider.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({
    super.key,
    required this.filter,
    required this.categories,
    required this.wallets,
    required this.onChanged,
    required this.onClear,
  });

  final TransactionFilter filter;
  final List<Category> categories;
  final List<Wallet> wallets;
  final ValueChanged<TransactionFilter> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final chips = <Widget>[];

    // Clear all chip (only shown when filter is active)
    if (filter.isActive) {
      chips.add(_clearChip(context, colorScheme));
    }

    // Type filter
    chips.add(_typeChip(context, colorScheme));

    // Wallet filter
    chips.add(_walletChip(context, colorScheme));

    // Category filter
    chips.add(_categoryChip(context, colorScheme));

    // Payment method filter
    chips.add(_paymentChip(context, colorScheme));

    // Date range filter
    chips.add(_dateChip(context, colorScheme));

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  // ── Clear all ─────────────────────────────────
  Widget _clearChip(BuildContext context, ColorScheme cs) {
    return ActionChip(
      avatar: const Icon(Icons.close, size: 14),
      label: const Text('Limpiar'),
      labelStyle: AppTextStyles.labelMedium.copyWith(color: cs.onError),
      backgroundColor: cs.error,
      side: BorderSide.none,
      onPressed: onClear,
    );
  }

  // ── Type ──────────────────────────────────────
  Widget _typeChip(BuildContext context, ColorScheme cs) {
    final selected = filter.type != null;
    return FilterChip(
      label: Text(
        filter.type?.label ?? 'Tipo',
        style: AppTextStyles.labelMedium.copyWith(
            color: selected ? cs.onPrimaryContainer : cs.onSurface),
      ),
      selected: selected,
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
      side: BorderSide(color: selected ? cs.primary : cs.outlineVariant,
          width: 0.5),
      onSelected: (_) => _showTypeSheet(context),
    );
  }

  Future<void> _showTypeSheet(BuildContext context) async {
    final result = await showModalBottomSheet<TransactionType?>(
      context: context,
      builder: (_) => _PickerSheet(
        title: 'Filtrar por tipo',
        items: TransactionType.values
            .map((t) => _SheetItem(label: t.label, value: t))
            .toList(),
        selected: filter.type,
      ),
    );
    if (result != null) {
      onChanged(filter.copyWith(type: result));
    } else if (result == null && filter.type != null) {
      onChanged(filter.copyWith(clearType: true));
    }
  }

  // ── Wallet ────────────────────────────────────
  Widget _walletChip(BuildContext context, ColorScheme cs) {
    final selected = filter.walletId != null;
    final walletName = selected
        ? wallets.firstWhere((w) => w.id == filter.walletId,
                orElse: () => wallets.first)
            .name
        : 'Billetera';
    return FilterChip(
      label: Text(
        walletName,
        style: AppTextStyles.labelMedium.copyWith(
            color: selected ? cs.onPrimaryContainer : cs.onSurface),
      ),
      selected: selected,
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
      side: BorderSide(color: selected ? cs.primary : cs.outlineVariant,
          width: 0.5),
      onSelected: wallets.isEmpty ? null : (_) => _showWalletSheet(context),
    );
  }

  Future<void> _showWalletSheet(BuildContext context) async {
    final result = await showModalBottomSheet<int?>(
      context: context,
      builder: (_) => _PickerSheet(
        title: 'Filtrar por billetera',
        items: wallets
            .map((w) => _SheetItem(label: w.name, value: w.id!))
            .toList(),
        selected: filter.walletId,
      ),
    );
    if (result != null) {
      onChanged(filter.copyWith(walletId: result));
    } else if (result == null && filter.walletId != null) {
      onChanged(filter.copyWith(clearWallet: true));
    }
  }

  // ── Category ──────────────────────────────────
  Widget _categoryChip(BuildContext context, ColorScheme cs) {
    final selected = filter.categoryId != null;
    final catName = selected
        ? categories.firstWhere((c) => c.id == filter.categoryId,
                orElse: () => categories.first)
            .name
        : 'Categoría';
    return FilterChip(
      label: Text(
        catName,
        style: AppTextStyles.labelMedium.copyWith(
            color: selected ? cs.onPrimaryContainer : cs.onSurface),
      ),
      selected: selected,
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
      side: BorderSide(color: selected ? cs.primary : cs.outlineVariant,
          width: 0.5),
      onSelected: categories.isEmpty ? null : (_) => _showCategorySheet(context),
    );
  }

  Future<void> _showCategorySheet(BuildContext context) async {
    final result = await showModalBottomSheet<int?>(
      context: context,
      builder: (_) => _PickerSheet(
        title: 'Filtrar por categoría',
        items: categories
            .map((c) => _SheetItem(
                label: '${c.icon}  ${c.name}', value: c.id!))
            .toList(),
        selected: filter.categoryId,
      ),
    );
    if (result != null) {
      onChanged(filter.copyWith(categoryId: result));
    } else if (result == null && filter.categoryId != null) {
      onChanged(filter.copyWith(clearCategory: true));
    }
  }

  // ── Payment method ────────────────────────────
  Widget _paymentChip(BuildContext context, ColorScheme cs) {
    final selected = filter.paymentMethod != null;
    return FilterChip(
      label: Text(
        filter.paymentMethod?.label ?? 'Método de pago',
        style: AppTextStyles.labelMedium.copyWith(
            color: selected ? cs.onPrimaryContainer : cs.onSurface),
      ),
      selected: selected,
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
      side: BorderSide(color: selected ? cs.primary : cs.outlineVariant,
          width: 0.5),
      onSelected: (_) => _showPaymentSheet(context),
    );
  }

  Future<void> _showPaymentSheet(BuildContext context) async {
    final result = await showModalBottomSheet<PaymentMethod?>(
      context: context,
      builder: (_) => _PickerSheet(
        title: 'Método de pago',
        items: PaymentMethod.values
            .map((p) => _SheetItem(
                label: '${p.emoji}  ${p.label}', value: p))
            .toList(),
        selected: filter.paymentMethod,
      ),
    );
    if (result != null) {
      onChanged(filter.copyWith(paymentMethod: result));
    } else if (result == null && filter.paymentMethod != null) {
      onChanged(filter.copyWith(clearPaymentMethod: true));
    }
  }

  // ── Date range ────────────────────────────────
  Widget _dateChip(BuildContext context, ColorScheme cs) {
    final selected = filter.dateFrom != null || filter.dateTo != null;
    String label = 'Fecha';
    if (filter.dateFrom != null && filter.dateTo != null) {
      label =
          '${filter.dateFrom!.day}/${filter.dateFrom!.month} – '
          '${filter.dateTo!.day}/${filter.dateTo!.month}';
    } else if (filter.dateFrom != null) {
      label = 'Desde ${filter.dateFrom!.day}/${filter.dateFrom!.month}';
    }

    return FilterChip(
      label: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
            color: selected ? cs.onPrimaryContainer : cs.onSurface),
      ),
      selected: selected,
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
      side: BorderSide(color: selected ? cs.primary : cs.outlineVariant,
          width: 0.5),
      onSelected: (_) => _showDatePicker(context),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: filter.dateFrom != null && filter.dateTo != null
          ? DateTimeRange(start: filter.dateFrom!, end: filter.dateTo!)
          : null,
    );
    if (range != null) {
      onChanged(filter.copyWith(
          dateFrom: range.start, dateTo: range.end));
    } else if (filter.dateFrom != null) {
      onChanged(filter.copyWith(clearDates: true));
    }
  }
}

// ─────────────────────────────────────────────
//  Generic picker bottom sheet
// ─────────────────────────────────────────────
class _SheetItem<T> {
  const _SheetItem({required this.label, required this.value});
  final String label;
  final T value;
}

class _PickerSheet<T> extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    this.selected,
  });

  final String title;
  final List<_SheetItem<T>> items;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: AppTextStyles.headingSmall
                  .copyWith(color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          const Divider(),
          // "All" option
          ListTile(
            leading: Icon(
              Icons.clear_all,
              color: colorScheme.onSurfaceVariant,
            ),
            title: Text('Todos',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: colorScheme.onSurface)),
            trailing: selected == null
                ? Icon(Icons.check_rounded, color: colorScheme.primary)
                : null,
            onTap: () => Navigator.of(context).pop(null),
          ),
          ...items.map((item) => ListTile(
                title: Text(item.label,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: colorScheme.onSurface)),
                trailing: selected == item.value
                    ? Icon(Icons.check_rounded,
                        color: colorScheme.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(item.value),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
