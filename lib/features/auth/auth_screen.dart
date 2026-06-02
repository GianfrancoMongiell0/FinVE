import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/logo_provider.dart';
import '../../core/services/auth_service.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/finve_logo.dart';
import 'widgets/pin_keypad.dart';
import 'widgets/pin_dots.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  String _pin = '';
  bool _hasError = false;
  bool _isBiometricAvailable = false;
  bool _isLoading = false;
  int _failedAttempts = 0;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final available = await AuthService.instance.isBiometricAvailable();
    final enabled = await AuthService.instance.isBiometricEnabled();
    final shouldUseBiometric = available && enabled;
    if (mounted) {
      setState(() => _isBiometricAvailable = shouldUseBiometric);
    }
    if (shouldUseBiometric) {
      // Small delay so the PIN screen renders before the biometric dialog appears
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _triggerBiometric();
    }
  }

  Future<void> _triggerBiometric() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final result = await AuthService.instance.attemptBiometric();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == AuthResult.success) {
      _navigateToMain();
    }
    // biometricFailed → let the user fall back to PIN (no action needed)
  }

  void _onKeyTap(String key) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += key;
      _hasError = false;
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), _verifyPin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _hasError = false;
    });
  }

  Future<void> _verifyPin() async {
    final correct = await AuthService.instance.verifyPin(_pin);
    if (!mounted) return;

    if (correct) {
      _navigateToMain();
    } else {
      _failedAttempts++;
      await _shakeController.forward(from: 0);
      setState(() {
        _hasError = true;
        _pin = '';
      });
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacementNamed('/main');
  }

  String get _errorText {
    if (_failedAttempts >= 3) {
      return 'PIN incorrecto ($_failedAttempts intentos fallidos)';
    }
    return 'PIN incorrecto. Inténtalo de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Logo dinámico
            Consumer(
              builder: (ctx, ref, _) {
                final logoId =
                    ref.watch(logoProvider).valueOrNull ?? AppLogoId.v4;
                return FinveLogo(logoId: logoId, size: 88);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'FinVe',
              style: AppTextStyles.displayMedium.copyWith(
                color: colorScheme.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa tu PIN para continuar',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 48),

            // PIN dots
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final t = _shakeController.value;
                final offset = t > 0
                    ? 12 * (0.5 - (t % 0.2) / 0.2).abs() * (t < 0.5 ? 1 : -1)
                    : 0.0;
                return Transform.translate(
                  offset: Offset(offset * 8, 0),
                  child: child,
                );
              },
              child: PinDots(
                length: 4,
                filled: _pin.length,
                hasError: _hasError,
              ),
            ),

            // Error message
            AnimatedOpacity(
              opacity: _hasError ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Keypad
            PinKeypad(
              onKeyTap: _onKeyTap,
              onDelete: _onDelete,
              extraAction: _isBiometricAvailable
                  ? PinKeypadAction(
                      icon: Icons.fingerprint_rounded,
                      onTap: _triggerBiometric,
                    )
                  : null,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
