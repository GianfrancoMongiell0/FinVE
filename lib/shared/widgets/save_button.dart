// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

enum _SaveState { idle, saving, success }

/// Botón de guardar con tres fases animadas:
///   idle    → label normal
///   saving  → spinner
///   success → check + scale 650ms → dispara Navigator.pop desde onSave
///
/// Uso:
///   SaveButton(label: 'Crear billetera', onSave: _save)
///   SaveButton(label: 'Registrar movimiento', onSave: _save, color: Colors.red)
class SaveButton extends StatefulWidget {
  const SaveButton({
    super.key,
    required this.label,
    required this.onSave,
    this.disabled = false,
    this.color,
  });

  final String label;
  final Future<void> Function() onSave;
  final bool disabled;

  /// Color de fondo idle. Null → colorScheme.primary.
  final Color? color;

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton>
    with SingleTickerProviderStateMixin {
  _SaveState _state = _SaveState.idle;
  late AnimationController _scaleCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_state != _SaveState.idle || widget.disabled) return;
    setState(() => _state = _SaveState.saving);
    try {
      await widget.onSave();
      if (!mounted) return;
      setState(() => _state = _SaveState.success);
      _scaleCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 650));
    } catch (_) {
      if (mounted) setState(() => _state = _SaveState.idle);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final idleColor = widget.color ?? colorScheme.primary;
    final isSuccess = _state == _SaveState.success;
    final isSaving = _state == _SaveState.saving;

    return ScaleTransition(
      scale: _scale,
      child: FilledButton(
        onPressed: (_state == _SaveState.idle && !widget.disabled)
            ? _handleTap
            : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: isSuccess ? colorScheme.tertiary : idleColor,
          disabledBackgroundColor: isSuccess
              ? colorScheme.tertiary
              : colorScheme.onSurface.withOpacity(0.12),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.75, end: 1.0).animate(anim),
              child: child,
            ),
          ),
          child: isSaving
              ? SizedBox(
                  key: const ValueKey('saving'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.onPrimary,
                  ),
                )
              : isSuccess
                  ? Row(
                      key: const ValueKey('success'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded,
                            size: 20, color: colorScheme.onTertiary),
                        const SizedBox(width: 8),
                        Text(
                          'Listo',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: colorScheme.onTertiary),
                        ),
                      ],
                    )
                  : Text(
                      key: const ValueKey('idle'),
                      widget.label,
                      style: AppTextStyles.labelLarge,
                    ),
        ),
      ),
    );
  }
}