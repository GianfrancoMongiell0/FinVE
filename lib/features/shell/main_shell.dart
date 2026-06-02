import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_text_styles.dart';
import '../budget/budget_screen.dart';
import '../calculator/calculator_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../wallets/wallets_screen.dart';
import '../transactions/transactions_screen.dart';
import '../priorities/priorities_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  static const _tabs = [
    _TabInfo(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Inicio',
    ),
    _TabInfo(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Billeteras',
    ),
    _TabInfo(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Movimientos',
    ),
    _TabInfo(
      icon: Icons.flag_outlined,
      activeIcon: Icons.flag_rounded,
      label: 'Metas',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Show global calculator FAB on all tabs except the calculator tab itself
    final showCalcFab = _currentIndex != 4;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: const [
              DashboardScreen(),
              WalletsScreen(),
              TransactionsScreen(),
              PrioritiesScreen(),
              CalculatorScreen(),
            ],
          ),

          // ── Global calculator FAB ────────────
          if (showCalcFab)
            Positioned(
              right: 16,
              bottom: 80, // above nav bar
              child: FloatingActionButton.small(
                heroTag: 'calc_fab',
                onPressed: () => showCalculatorSheet(context),
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                elevation: 2,
                tooltip: 'Calculadora',
                child: const Icon(Icons.calculate_outlined, size: 20),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon:
                    Icon(t.activeIcon, color: colorScheme.primary),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabInfo {
  const _TabInfo({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

// Provider to programmatically navigate to a tab from anywhere
final shellTabProvider = StateProvider<int>((ref) => 0);
