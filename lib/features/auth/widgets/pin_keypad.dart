// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../../../shared/theme/app_text_styles.dart';

class PinKeypadAction {
  const PinKeypadAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
}

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onKeyTap,
    required this.onDelete,
    this.extraAction,
  });

  final ValueChanged<String> onKeyTap;
  final VoidCallback onDelete;

  /// Optional left-side action on the bottom row (e.g. biometric button).
  final PinKeypadAction? extraAction;

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          ..._keys.map(
            (row) => Row(
              children: row.map((key) => _buildKey(context, key)).toList(),
            ),
          ),
          // Bottom row: extra action | 0 | delete
          Row(
            children: [
              _buildExtraAction(context),
              _buildKey(context, '0'),
              _buildDeleteKey(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(BuildContext context, String digit) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onKeyTap(digit),
            borderRadius: BorderRadius.circular(40),
            splashColor: colorScheme.primary.withOpacity(0.12),
            highlightColor: colorScheme.primary.withOpacity(0.06),
            child: Container(
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                digit,
                style: AppTextStyles.headingLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(40),
            child: Container(
              height: 68,
              alignment: Alignment.center,
              child: Icon(
                Icons.backspace_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraAction(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (extraAction == null) return const Expanded(child: SizedBox(height: 68));
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: extraAction!.onTap,
            borderRadius: BorderRadius.circular(40),
            child: Container(
              height: 68,
              alignment: Alignment.center,
              child: Icon(
                extraAction!.icon,
                color: colorScheme.primary,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
