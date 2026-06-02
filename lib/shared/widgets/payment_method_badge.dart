import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PaymentMethodBadge extends StatelessWidget {
  const PaymentMethodBadge({
    super.key,
    required this.method,
    this.compact = false,
  });

  final PaymentMethod method;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bg =
        PaymentColors.background[method.key] ?? const Color(0xFFF1EFE8);
    final fg =
        PaymentColors.foreground[method.key] ?? const Color(0xFF444441);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Text(method.emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
          ],
          Text(
            compact ? _shortLabel(method) : method.label,
            style: (compact
                    ? AppTextStyles.labelSmall
                    : AppTextStyles.labelMedium)
                .copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  String _shortLabel(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.pagoMovil => 'P.Móvil',
    PaymentMethod.transfer => 'Trans.',
    PaymentMethod.zelle => 'Zelle',
    PaymentMethod.other => 'Otro',
  };
}
