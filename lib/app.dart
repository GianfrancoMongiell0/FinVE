// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/auth_service.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/app_colors.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/pin_setup_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/budget/budget_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'core/providers/logo_provider.dart';
import 'shared/widgets/finve_logo.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/screens/recurring_settings_screen.dart';

class FinVeApp extends ConsumerWidget {
  const FinVeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeProvider);
    final themeId = themeAsync.valueOrNull ?? AppThemeId.oceanBlue;
    final (lightTheme, darkTheme) = AppTheme.forId(themeId);

    return MaterialApp(
      title: 'FinVe',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const _AuthGate(),
      routes: {
        '/main': (_) => const MainShell(),
        '/pin-setup': (_) => const PinSetupScreen(),
        '/pin-change': (_) => const PinSetupScreen(isChange: true),
        '/auth': (_) => const AuthScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/settings/recurring': (_) => const RecurringSettingsScreen(),
        '/budget': (_) => const BudgetScreen(),
        '/calendar': (_) => const CalendarScreen(),
      },
    );
  }
}

/// Decides which screen to show on cold launch.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _loading = true;
  bool _pinSet = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final results = await Future.wait([
      AuthService.instance.isPinSet(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);
    if (mounted) {
      setState(() {
        _pinSet = results[0] as bool;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SplashScreen();
    if (!_pinSet) return const PinSetupScreen();
    return const AuthScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Consumer(
          builder: (ctx, ref, _) {
            final logoId = ref.watch(logoProvider).valueOrNull ?? AppLogoId.v4;
            return FinveLogo(logoId: logoId, size: 120);
          },
        ),
      ),
    );
  }
}
