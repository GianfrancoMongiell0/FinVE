// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CurrencyBadge extends StatelessWidget {
  const CurrencyBadge({
    super.key,
    required this.currencyCode,
    this.showFlag = true,
    this.compact = false,
  });

  final String currencyCode;
  final bool showFlag;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final code = currencyCode.toUpperCase();
    final bg = CurrencyColors.background[code] ?? const Color(0xFFF1EFE8);
    final fg = CurrencyColors.foreground[code] ?? const Color(0xFF444441);
    final flag = showFlag ? CurrencyCodes.flag(code) : null;

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
          if (flag != null && !compact) ...[
            Text(flag, style: TextStyle(fontSize: compact ? 10 : 12)),
            const SizedBox(width: 4),
          ],
          Text(
            code,
            style: (compact
                    ? AppTextStyles.labelSmall
                    : AppTextStyles.labelMedium)
                .copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
