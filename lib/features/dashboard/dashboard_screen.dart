import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/rate_provider.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_box.dart';
import '../transactions/transaction_form_screen.dart';
import '../shell/main_shell.dart';
import 'dashboard_provider.dart';
import 'widgets/balance_cards.dart';
import 'widgets/budget_summary.dart';
import 'widgets/balance_chart.dart';
import 'widgets/rate_strip.dart';
import 'widgets/recent_transactions.dart';
import 'widgets/category_chart.dart';
import 'widgets/monthly_summary.dart';
import 'widgets/upcoming_recurring.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: dashAsync.when(
        loading: () => const _LoadingShell(),
        error: (e, _) => Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Error al cargar',
            subtitle: e.toString(),
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(dashboardProvider),
          ),
        ),
        data: (state) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(rateProvider.notifier).forceRefresh();
            ref.invalidate(dashboardProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: colorScheme.surface,
                elevation: 0,
                scrolledUnderElevation: 1,
                title: _Greeting(),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/settings'),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _FadeSlide(
                      delay: const Duration(milliseconds: 0),
                      child: BalanceCards(
                        totalUsd: state.totalUsd,
                        totalVesBcv: state.totalVesBcv,
                        walletSummaries: state.walletSummaries,
                        rates: state.rates,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Quick access row ────────────────
                    _FadeSlide(
                      delay: const Duration(milliseconds: 80),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _QuickAccessButton(
                              icon: Icons.calendar_month_outlined,
                              label: 'Calendario',
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/calendar'),
                            ),
                            const SizedBox(width: 10),
                            _QuickAccessButton(
                              icon: Icons.pie_chart_outline_rounded,
                              label: 'Presupuesto',
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/budget'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FadeSlide(
                      delay: const Duration(milliseconds: 140),
                      child: const RateStrip(),
                    ),
                    const SizedBox(height: 24),
                    _FadeSlide(
                      delay: const Duration(milliseconds: 200),
                      child: BalanceChart(points: state.chartData),
                    ),
                    const SizedBox(height: 24),

                    // ── Budget summary ─────────────
                    _FadeSlide(
                      delay: const Duration(milliseconds: 250),
                      child: const BudgetSummaryCard(),
                    ),
                    const SizedBox(height: 24),

                    // ── Monthly summary ────────────
                    if (state.monthlySummary != null) ...[
                      MonthlySummaryCard(summary: state.monthlySummary!),
                      const SizedBox(height: 24),
                    ],

                    // ── Category chart ─────────────
                    if (state.categoryExpenses.isNotEmpty) ...[
                      CategoryChart(expenses: state.categoryExpenses),
                      const SizedBox(height: 24),
                    ],

                    if (state.upcomingRecurring.isNotEmpty) ...[
                      UpcomingRecurring(
                        expenses: state.upcomingRecurring,
                        onManage: () => Navigator.of(context)
                            .pushNamed('/settings/recurring'),
                      ),
                      const SizedBox(height: 24),
                    ],
                    RecentTransactions(
                      transactions: state.recentTransactions,
                      rates: state.rates,
                      onViewAll: () {
                        ref.read(shellTabProvider.notifier).state = 2;
                      },
                      onTap: (tx) => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TransactionFormScreen(transaction: tx),
                          fullscreenDialog: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 88),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard_fab',
        onPressed: () => _showQuickAdd(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo movimiento'),
      ),
    );
  }

  void _showQuickAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TransactionFormScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? '¡Buenos días!'
        : hour < 18
            ? '¡Buenas tardes!'
            : '¡Buenas noches!';
    final now = DateTime.now();
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    final dateStr = '${now.day} de ${months[now.month - 1]}';
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting,
            style: AppTextStyles.headingMedium
                .copyWith(color: colorScheme.onSurface)),
        Text(dateStr,
            style: AppTextStyles.caption
                .copyWith(color: colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _LoadingShell extends StatelessWidget {
  const _LoadingShell();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(floating: true, title: SizedBox.shrink()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Balance card skeleton
                const SkeletonBox(
                    width: double.infinity, height: 172, borderRadius: 20),
                const SizedBox(height: 16),
                // Quick access buttons skeleton
                Row(children: [
                  const Expanded(
                      child: SkeletonBox(width: double.infinity, height: 44)),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: SkeletonBox(width: double.infinity, height: 44)),
                ]),
                const SizedBox(height: 16),
                // Rate strip skeleton
                const SkeletonBox(width: double.infinity, height: 52),
                const SizedBox(height: 24),
                // Chart skeleton
                const SkeletonBox(width: double.infinity, height: 160),
                const SizedBox(height: 24),
                // Monthly summary skeleton
                const SkeletonBox(width: double.infinity, height: 100),
                const SizedBox(height: 24),
                // Category chart skeleton
                Row(children: [
                  const SkeletonBox(width: 120, height: 120, borderRadius: 60),
                  const SizedBox(width: 16),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonBox(width: 100, height: 16),
                        const SizedBox(height: 8),
                        const SkeletonBox(width: 80, height: 16),
                        const SizedBox(height: 8),
                        const SkeletonBox(width: 90, height: 16),
                      ]),
                ]),
                const SizedBox(height: 24),
                // Recent transactions skeleton
                const SkeletonBox(width: 140, height: 20),
                const SizedBox(height: 12),
                const SkeletonBox(width: double.infinity, height: 60),
                const SizedBox(height: 8),
                const SkeletonBox(width: double.infinity, height: 60),
                const SizedBox(height: 8),
                const SkeletonBox(width: double.infinity, height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Fade + slide-up animation for dashboard items.
class _FadeSlide extends StatefulWidget {
  const _FadeSlide({required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<_FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

class _QuickAccessButton extends StatelessWidget {
  const _QuickAccessButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelMedium
                    .copyWith(color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
