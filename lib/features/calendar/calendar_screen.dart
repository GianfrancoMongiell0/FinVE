// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/daos/category_dao.dart';
import '../../core/database/daos/transaction_dao.dart';
import '../../core/models/transaction.dart' as app_models;
import '../../core/models/category.dart';
import '../../core/utils/formatters.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/payment_method_badge.dart';
import '../transactions/transaction_form_screen.dart';

// ── Provider ─────────────────────────────────
final _calendarMonthProvider = StateProvider<DateTime>(
    (ref) => DateTime(DateTime.now().year, DateTime.now().month));

final _calendarTxProvider =
    FutureProvider.family<Map<String, List<app_models.Transaction>>, DateTime>(
        (ref, month) async {
  final from = DateTime(month.year, month.month, 1);
  final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

  final txs = await TransactionDao.instance.getFiltered(
    dateFrom: from,
    dateTo: to,
  );

  final categories = await CategoryDao.instance.getAll();
  final catMap = {for (final c in categories) c.id!: c};

  final enriched = txs.map((tx) {
    final cat = tx.categoryId != null ? catMap[tx.categoryId] : null;
    return tx.copyWith(category: cat);
  }).toList();

  // Group by day key "yyyy-MM-dd"
  final Map<String, List<app_models.Transaction>> map = {};
  for (final tx in enriched) {
    final key =
        '${tx.date.year.toString().padLeft(4, '0')}-'
        '${tx.date.month.toString().padLeft(2, '0')}-'
        '${tx.date.day.toString().padLeft(2, '0')}';
    map.putIfAbsent(key, () => []).add(tx);
  }
  return map;
});

const _monthNames = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
];

const _weekDays = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'];

// ── Screen ────────────────────────────────────
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(_calendarMonthProvider);
    final txAsync = ref.watch(_calendarTxProvider(month));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
      ),
      body: Column(
        children: [
          // ── Month navigator ──────────────────
          Container(
            color: colorScheme.surfaceContainerLow,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () {
                          final prev = DateTime(month.year, month.month - 1);
                          ref.read(_calendarMonthProvider.notifier).state =
                              prev;
                          setState(() => _selectedDay = null);
                        },
                      ),
                      Expanded(
                        child: Text(
                          '${_monthNames[month.month - 1]} ${month.year}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headingSmall,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: _isCurrentMonth(month)
                              ? colorScheme.outlineVariant
                              : null,
                        ),
                        onPressed: _isCurrentMonth(month)
                            ? null
                            : () {
                                final next =
                                    DateTime(month.year, month.month + 1);
                                ref
                                    .read(_calendarMonthProvider.notifier)
                                    .state = next;
                                setState(() => _selectedDay = null);
                              },
                      ),
                    ],
                  ),
                ),

                // Weekday headers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: _weekDays
                        .map((d) => Expanded(
                              child: Center(
                                child: Text(
                                  d,
                                  style: AppTextStyles.caption.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 4),

                // Calendar grid
                txAsync.when(
                  loading: () => const SizedBox(
                      height: 240,
                      child:
                          Center(child: CircularProgressIndicator())),
                  error: (e, _) => const SizedBox(height: 240),
                  data: (txMap) => _CalendarGrid(
                    month: month,
                    txMap: txMap,
                    selectedDay: _selectedDay,
                    onDayTap: (day) =>
                        setState(() => _selectedDay = day),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Day detail ───────────────────────
          Expanded(
            child: txAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (txMap) {
                if (_selectedDay == null) {
                  return _EmptyDayHint();
                }
                final key =
                    '${_selectedDay!.year.toString().padLeft(4, '0')}-'
                    '${_selectedDay!.month.toString().padLeft(2, '0')}-'
                    '${_selectedDay!.day.toString().padLeft(2, '0')}';
                final txs = txMap[key] ?? [];

                if (txs.isEmpty) {
                  return _EmptyDay(day: _selectedDay!);
                }
                return _DayDetail(
                  day: _selectedDay!,
                  transactions: txs,
                  onEdit: (tx) async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TransactionFormScreen(transaction: tx),
                        fullscreenDialog: true,
                      ),
                    );
                    // Refresh
                    ref.invalidate(_calendarTxProvider(month));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentMonth(DateTime m) {
    final now = DateTime.now();
    return m.year == now.year && m.month == now.month;
  }
}

// ── Calendar Grid ────────────────────────────
class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.txMap,
    required this.selectedDay,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<String, List<app_models.Transaction>> txMap;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final firstDay = DateTime(month.year, month.month, 1);
    // Monday = 0 offset
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - startOffset + 1;

              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 44));
              }

              final date = DateTime(month.year, month.month, dayNum);
              final key =
                  '${date.year.toString().padLeft(4, '0')}-'
                  '${date.month.toString().padLeft(2, '0')}-'
                  '${date.day.toString().padLeft(2, '0')}';
              final dayTxs = txMap[key] ?? [];
              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
              final isSelected = selectedDay != null &&
                  selectedDay!.year == date.year &&
                  selectedDay!.month == date.month &&
                  selectedDay!.day == date.day;
              final isFuture = date.isAfter(now);

              // Dot colors
              final hasIncome =
                  dayTxs.any((t) => t.isIncome);
              final hasExpense =
                  dayTxs.any((t) => t.isExpense);

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDayTap(date),
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : isToday
                              ? colorScheme.primaryContainer
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : isFuture
                                    ? colorScheme.outlineVariant
                                    : colorScheme.onSurface,
                            fontWeight: isToday || isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        if (dayTxs.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hasExpense)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                            .withOpacity(0.8)
                                        : colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (hasIncome)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                            .withOpacity(0.8)
                                        : const Color(0xFF1D9E75),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

// ── Day Detail ───────────────────────────────
class _DayDetail extends StatelessWidget {
  const _DayDetail({
    required this.day,
    required this.transactions,
    required this.onEdit,
  });

  final DateTime day;
  final List<app_models.Transaction> transactions;
  final ValueChanged<app_models.Transaction> onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    double totalIncome = 0;
    double totalExpense = 0;
    for (final tx in transactions) {
      if (tx.isIncome) totalIncome += tx.amount;
      else totalExpense += tx.amount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          child: Row(
            children: [
              Text(
                _formatDay(day),
                style: AppTextStyles.labelLarge
                    .copyWith(color: colorScheme.onSurface),
              ),
              const Spacer(),
              if (totalIncome > 0)
                Text(
                  '+${Formatters.usd(totalIncome)}',
                  style: AppTextStyles.labelMedium.copyWith(
                      color: const Color(0xFF1D9E75)),
                ),
              if (totalIncome > 0 && totalExpense > 0)
                const SizedBox(width: 8),
              if (totalExpense > 0)
                Text(
                  '-${Formatters.usd(totalExpense)}',
                  style: AppTextStyles.labelMedium.copyWith(
                      color: colorScheme.error),
                ),
            ],
          ),
        ),

        // Transaction list
        Expanded(
          child: ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (_, i) {
              final tx = transactions[i];
              final isIncome = tx.isIncome;
              final amountColor = isIncome
                  ? const Color(0xFF1D9E75)
                  : colorScheme.error;

              return InkWell(
                onTap: () => onEdit(tx),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            tx.category?.icon ?? '📦',
                            style:
                                const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.category?.name ??
                                  'Sin categoría',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(
                                      color: colorScheme.onSurface),
                            ),
                            Row(
                              children: [
                                PaymentMethodBadge(
                                    method: tx.paymentMethod,
                                    compact: true),
                                if (tx.note != null &&
                                    tx.note!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      tx.note!,
                                      style: AppTextStyles.caption
                                          .copyWith(
                                              color: colorScheme
                                                  .onSurfaceVariant),
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '−'}${Formatters.usd(tx.amount)}',
                        style: AppTextStyles.amountSmall
                            .copyWith(color: amountColor),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDay(DateTime d) {
    const days = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo'
    ];
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }
}

// ── Empty states ─────────────────────────────
class _EmptyDayHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Text(
            'Toca un día para ver los movimientos',
            style: AppTextStyles.bodySmall.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          child: Text(
            _fmt(day),
            style: AppTextStyles.labelLarge
                .copyWith(color: colorScheme.onSurface),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 36, color: colorScheme.outlineVariant),
                const SizedBox(height: 8),
                Text(
                  'Sin movimientos este día',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}