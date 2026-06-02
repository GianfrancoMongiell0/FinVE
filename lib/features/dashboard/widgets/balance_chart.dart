import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../dashboard_provider.dart';

class BalanceChart extends StatelessWidget {
  const BalanceChart({super.key, required this.points, this.isLoading = false});

  final List<ChartPoint> points;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Text(
                'Evolución del balance',
                style: AppTextStyles.headingSmall
                    .copyWith(color: colorScheme.onSurface),
              ),
              const Spacer(),
              Text(
                'Últimos 30 días',
                style: AppTextStyles.caption
                    .copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: isLoading
              ? _ChartSkeleton()
              : points.length < 2
                  ? _EmptyChart()
                  : _Chart(points: points),
        ),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.points});
  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final minY = points.map((p) => p.balanceUsd).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.balanceUsd).reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs();
    final padding = range * 0.15;

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.balanceUsd);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
      child: LineChart(
        LineChartData(
          minY: minY - padding,
          maxY: maxY + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 3 : 1,
            getDrawingHorizontalLine: (_) => FlLine(
              color: colorScheme.outlineVariant.withOpacity(0.4),
              strokeWidth: 0.8,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: range > 0 ? range / 3 : 1,
                getTitlesWidget: (v, _) => Text(
                  Formatters.compactUsd(v),
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: (points.length / 4).ceilToDouble(),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final date = points[idx].date;
                  return Text(
                    '${date.day}/${date.month}',
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: colorScheme.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.18),
                    colorScheme.primary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.x.toInt();
                final date = idx < points.length ? points[idx].date : null;
                return LineTooltipItem(
                  '${date != null ? '${date.day}/${date.month}\n' : ''}'
                  '${Formatters.usd(s.y)}',
                  AppTextStyles.labelSmall.copyWith(color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart_rounded,
              color: colorScheme.outlineVariant, size: 32),
          const SizedBox(height: 8),
          Text(
            'Sin datos de balance aún',
            style: AppTextStyles.bodySmall
                .copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ChartSkeleton extends StatefulWidget {
  @override
  State<_ChartSkeleton> createState() => _ChartSkeletonState();
}

class _ChartSkeletonState extends State<_ChartSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest
              .withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
