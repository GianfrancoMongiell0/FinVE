import 'package:flutter/material.dart';

class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.hasError = false,
  });

  final int length;
  final int filled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        final color = hasError
            ? colorScheme.error
            : isFilled
                ? colorScheme.primary
                : colorScheme.outlineVariant;

        // Fixed-size container prevents dots from shifting during shake
        return SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: isFilled ? 18 : 14,
              height: isFilled ? 18 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? color : Colors.transparent,
                border: Border.all(color: color, width: 2),
              ),
            ),
          ),
        );
      }),
    );
  }
}
