// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/formatters.dart';
import '../theme/app_text_styles.dart';
import 'currency_badge.dart';

enum AmountSize { large, medium, small }

class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.amount,
    required this.currencyCode,
    this.usdEquivalent,
    this.size = AmountSize.medium,
    this.showBadge = true,
    this.isNegative,
    this.alignment = CrossAxisAlignment.start,
  });

  final double amount;
  final String currencyCode;

  /// If provided, shows a secondary line with the USD equivalent.
  final double? usdEquivalent;

  final AmountSize size;
  final bool showBadge;

  /// Explicit sign override; if null, derived from [amount] sign.
  final bool? isNegative;

  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final negative = isNegative ?? amount < 0;
    final absAmount = amount.abs();

    final primaryColor = negative
        ? colorScheme.error
        : (currencyCode == CurrencyCodes.usd
              ? colorScheme.primary
              : colorScheme.onSurface);

    final primaryStyle = switch (size) {
      AmountSize.large => AppTextStyles.amountLarge,
      AmountSize.medium => AppTextStyles.amountMedium,
      AmountSize.small => AppTextStyles.amountSmall,
    };

    final secondaryStyle = AppTextStyles.bodySmall.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sign prefix
            if (negative || (!negative && amount > 0))
              Text(
                negative ? '−' : '+',
                style: primaryStyle.copyWith(color: primaryColor),
              ),

            const SizedBox(width: 1),

            // Amount
            Text(
              Formatters.byCurrency(absAmount, currencyCode),
              style: primaryStyle.copyWith(color: primaryColor),
            ),

            // Currency badge
            if (showBadge && currencyCode != CurrencyCodes.usd) ...[
              const SizedBox(width: 6),
              CurrencyBadge(
                currencyCode: currencyCode,
                compact: size == AmountSize.small,
                showFlag: size != AmountSize.small,
              ),
            ],
          ],
        ),

        // USD equivalent secondary line
        if (usdEquivalent != null &&
            currencyCode != CurrencyCodes.usd) ...[
          const SizedBox(height: 2),
          Text(
            Formatters.usd(usdEquivalent!),
            style: secondaryStyle,
          ),
        ],
      ],
    );
  }
}
