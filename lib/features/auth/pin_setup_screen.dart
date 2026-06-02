import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../shared/theme/app_text_styles.dart';
import 'widgets/pin_keypad.dart';
import 'widgets/pin_dots.dart';

enum _SetupStep { enter, confirm }

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key, this.isChange = false});

  /// True when called from Settings to change an existing PIN.
  final bool isChange;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  _SetupStep _step = _SetupStep.enter;
  String _firstPin = '';
  String _currentPin = '';
  bool _hasError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    if (_currentPin.length >= 4) return;
    setState(() {
      _currentPin += key;
      _hasError = false;
    });
    if (_currentPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), _handleComplete);
    }
  }

  void _onDelete() {
    if (_currentPin.isEmpty) return;
    setState(() {
      _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      _hasError = false;
    });
  }

  Future<void> _handleComplete() async {
    if (_step == _SetupStep.enter) {
      setState(() {
        _firstPin = _currentPin;
        _currentPin = '';
        _step = _SetupStep.confirm;
      });
    } else {
      if (_currentPin == _firstPin) {
        await AuthService.instance.savePin(_currentPin);
        if (mounted) {
          if (widget.isChange) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN actualizado correctamente')),
            );
            Navigator.of(context).pop(true);
          } else {
            // Navigate to main shell after first-time setup
            Navigator.of(context).pushReplacementNamed('/main');
          }
        }
      } else {
        // PINs don't match — shake and reset
        await _shakeController.forward(from: 0);
        setState(() {
          _hasError = true;
          _currentPin = '';
          _step = _SetupStep.enter;
          _firstPin = '';
        });
      }
    }
  }

  String get _titleText {
    if (_step == _SetupStep.enter) {
      return widget.isChange ? 'Nuevo PIN' : 'Crea tu PIN';
    }
    return 'Confirma tu PIN';
  }

  String get _subtitleText {
    if (_step == _SetupStep.enter) {
      return widget.isChange
          ? 'Elige un PIN de 4 dígitos'
          : 'Elige un PIN de 4 dígitos para proteger tu app';
    }
    return 'Ingresa el mismo PIN de nuevo';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: widget.isChange
          ? AppBar(
              leading: const BackButton(),
              title: const Text('Cambiar PIN'),
              backgroundColor: colorScheme.surface,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Logo / icon
            if (!widget.isChange) ...[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 36,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Title
            Text(
              _titleText,
              style: AppTextStyles.headingLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitleText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // PIN dots with shake animation
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final offset = _shakeController.isAnimating
                    ? 8 *
                        (0.5 - (_shakeAnimation.value % 0.5).abs()) *
                        (_shakeAnimation.value < 0.5 ? 1 : -1)
                    : 0.0;
                return Transform.translate(
                  offset: Offset(offset * 10, 0),
                  child: child,
                );
              },
              child: PinDots(
                length: 4,
                filled: _currentPin.length,
                hasError: _hasError,
              ),
            ),

            if (_hasError) ...[
              const SizedBox(height: 12),
              Text(
                'Los PINs no coinciden. Inténtalo de nuevo.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],

            const Spacer(),

            // Keypad
            PinKeypad(
              onKeyTap: _onKeyTap,
              onDelete: _onDelete,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
