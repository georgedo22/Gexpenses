import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/presentation/widgets/charts/report_panel.dart';

/// Bar chart for report trends with touch tooltips and a text alternative
/// for screen readers.
class ReportBarChart extends StatelessWidget {
  const ReportBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.semanticsLabel,
  });

  final List<double> values;
  final List<String> labels;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);
    final barWidth = values.length > 8 ? 8.0 : 14.0;
    final height = (MediaQuery.sizeOf(context).width * 0.45).clamp(
      170.0,
      230.0,
    );

    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: ReportPanel(
        child: SizedBox(
          height: height,
          child: BarChart(
            swapAnimationDuration: AppMotion.resolve(context, AppMotion.slow),
            swapAnimationCurve: AppMotion.emphasized,
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue <= 0 ? 1.0 : maxValue * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem:
                      (
                        group,
                        groupIndex,
                        rod,
                        rodIndex,
                      ) => BarTooltipItem(
                        CurrencyFormatter.format(rod.toY),
                        textTheme.labelSmall!.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsetsDirectional.only(top: 6),
                      child: Text(
                        labels[value.toInt().clamp(0, labels.length - 1)],
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < values.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        width: barWidth,
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
