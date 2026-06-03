// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE


import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../dashboard_provider.dart';

class CategoryChart extends StatefulWidget {
  const CategoryChart({super.key, required this.expenses});
  final List<CategoryExpense> expenses;

  @override
  State<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<CategoryChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.expenses.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline,
                  color: colorScheme.outlineVariant, size: 32),
              const SizedBox(height: 8),
              Text(
                'Sin gastos este mes',
                style: AppTextStyles.bodySmall
                    .copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final colors = _generateColors(widget.expenses.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Text('Gastos por categoría',
                  style: AppTextStyles.headingSmall
                      .copyWith(color: colorScheme.onSurface)),
              const Spacer(),
              Text('Este mes',
                  style: AppTextStyles.caption
                      .copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Pie chart
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          setState(() => _touchedIndex = -1);
                          return;
                        }
                        setState(() => _touchedIndex =
                            response.touchedSection!.touchedSectionIndex);
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                    sections: widget.expenses.asMap().entries.map((e) {
                      final isTouched = e.key == _touchedIndex;
                      return PieChartSectionData(
                        color: colors[e.key],
                        value: e.value.percentage,
                        title: isTouched
                            ? '${e.value.percentage.toStringAsFixed(0)}%'
                            : '',
                        radius: isTouched ? 52 : 44,
                        titleStyle: AppTextStyles.labelSmall
                            .copyWith(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.expenses.asMap().entries.map((e) {
                    final isSelected = e.key == _touchedIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[e.key],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(e.value.category.icon,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              e.value.category.name,
                              style: AppTextStyles.caption.copyWith(
                                color: isSelected
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            Formatters.usd(e.value.totalUsd),
                            style: AppTextStyles.caption.copyWith(
                              color: isSelected
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Color> _generateColors(int count) {
    final palette = CategoryColorPalette.colors;
    return List.generate(count, (i) => palette[i % palette.length]);
  }
}
