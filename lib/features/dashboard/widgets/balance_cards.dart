import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/currency_rates.dart';
import '../../../core/providers/balance_visibility_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/theme/app_theme.dart';
import '../dashboard_provider.dart';

class BalanceCards extends ConsumerStatefulWidget {
  const BalanceCards({
    super.key,
    required this.totalUsd,
    required this.totalVesBcv,
    required this.walletSummaries,
    required this.rates,
  });

  final double totalUsd;
  final double totalVesBcv;
  final List<WalletSummary> walletSummaries;
  final CurrencyRates rates;

  @override
  ConsumerState<BalanceCards> createState() => _BalanceCardsState();
}

class _BalanceCardsState extends ConsumerState<BalanceCards> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visible = ref.watch(balanceVisibleProvider);
    final themeId =
        ref.watch(themeProvider).valueOrNull ?? AppThemeId.oceanBlue;
    final brightness = Theme.of(context).brightness;
    final gradients = AppTheme.cardGradients(themeId, brightness);

    return Column(
      children: [
        // Eye toggle button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () =>
                    ref.read(balanceVisibleProvider.notifier).state = !visible,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        visible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        visible ? 'Ocultar' : 'Mostrar',
                        style: AppTextStyles.caption
                            .copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 172,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _UsdCard(
                  totalUsd: widget.totalUsd,
                  visible: visible,
                  gradient: gradients[0]),
              _VesCard(
                totalVesBcv: widget.totalVesBcv,
                bcvRate: widget.rates.bcvRate,
                visible: visible,
                gradient: gradients[1],
              ),
              _AssetBreakdownCard(
                summaries: widget.walletSummaries,
                visible: visible,
                gradient: gradients[2],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color:
                    active ? colorScheme.primary : colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Shared masked amount widget ───────────────
class _MaskedAmount extends StatelessWidget {
  const _MaskedAmount(
      {required this.text, required this.visible, required this.style});
  final String text;
  final bool visible;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (visible) return Text(text, style: style);
    return Text('••••••', style: style.copyWith(letterSpacing: 4));
  }
}

// ── Card 1: Total in USD ──────────────────────
class _UsdCard extends StatefulWidget {
  const _UsdCard(
      {required this.totalUsd,
      required this.visible,
      required this.gradient});
  final double totalUsd;
  final bool visible;
  final LinearGradient gradient;

  @override
  State<_UsdCard> createState() => _UsdCardState();
}

class _UsdCardState extends State<_UsdCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prevValue = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: widget.totalUsd)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_UsdCard old) {
    super.didUpdateWidget(old);
    if (old.totalUsd != widget.totalUsd) {
      _prevValue = old.totalUsd;
      _anim = Tween<double>(begin: _prevValue, end: widget.totalUsd)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      gradient: widget.gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 6),
              Text('Balance total',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: Colors.white.withOpacity(0.8))),
            ],
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => _MaskedAmount(
              text: Formatters.usd(_anim.value),
              visible: widget.visible,
              style: AppTextStyles.amountLarge.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text('en dólares estadounidenses',
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white.withOpacity(0.7))),
        ],
      ),
    );
  }
}

// ── Card 2: Total in VES (BCV) ────────────────
class _VesCard extends StatelessWidget {
  const _VesCard(
      {required this.totalVesBcv,
      required this.bcvRate,
      required this.visible,
      required this.gradient});
  final double totalVesBcv;
  final double bcvRate;
  final bool visible;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      gradient: gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🇻🇪', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('Balance en bolívares',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: Colors.white.withOpacity(0.8))),
            ],
          ),
          const Spacer(),
          _MaskedAmount(
            text: bcvRate > 0 ? Formatters.ves(totalVesBcv) : '—',
            visible: visible,
            style: AppTextStyles.amountLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            bcvRate > 0
                ? 'Tasa BCV: ${Formatters.rate(bcvRate)}'
                : 'Tasa BCV no disponible',
            style: AppTextStyles.caption
                .copyWith(color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

// ── Card 3: Per-asset breakdown ───────────────
class _AssetBreakdownCard extends StatelessWidget {
  const _AssetBreakdownCard(
      {required this.summaries,
      required this.visible,
      required this.gradient});
  final List<WalletSummary> summaries;
  final bool visible;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      gradient: gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis billeteras',
              style: AppTextStyles.labelMedium
                  .copyWith(color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 8),
          if (summaries.isEmpty)
            Text('Sin billeteras aún',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.white.withOpacity(0.6)))
          else
            ...summaries.take(3).map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(CurrencyCodes.flag(s.wallet.currencyCode),
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.wallet.name,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      visible
                          ? Text(
                              Formatters.byCurrency(
                                  s.wallet.balance, s.wallet.currencyCode),
                              style: AppTextStyles.amountSmall
                                  .copyWith(color: Colors.white),
                            )
                          : Text('••••',
                              style: AppTextStyles.amountSmall.copyWith(
                                  color: Colors.white, letterSpacing: 3)),
                    ],
                  ),
                )),
          if (summaries.length > 3)
            Text('+${summaries.length - 3} más',
                style: AppTextStyles.caption
                    .copyWith(color: Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }
}

// ── Shared card shell ─────────────────────────
class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, required this.gradient});
  final Widget child;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}