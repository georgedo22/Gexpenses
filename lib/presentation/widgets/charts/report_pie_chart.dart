import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/widgets/charts/report_panel.dart';

/// Interactive pie chart of spending by category.
///
/// Touching a slice highlights it and shows its amount in the center; the
/// center otherwise shows the number of categories. A text alternative is
/// exposed to screen readers via [semanticsLabel].
class ReportPieChart extends StatefulWidget {
  const ReportPieChart({
    super.key,
    required this.breakdown,
    required this.semanticsLabel,
  });

  final Map<ExpenseCategory, double> breakdown;
  final String semanticsLabel;

  @override
  State<ReportPieChart> createState() => _ReportPieChartState();
}

class _ReportPieChartState extends State<ReportPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final total = widget.breakdown.values.fold<double>(0, (sum, v) => sum + v);

    final entries = widget.breakdown.entries.toList();
    final touched = _touchedIndex != null && _touchedIndex! < entries.length
        ? entries[_touchedIndex!]
        : null;

    return Semantics(
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: ReportPanel(
        child: SizedBox(
          height: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                swapAnimationDuration: AppMotion.resolve(
                  context,
                  AppMotion.slow,
                ),
                swapAnimationCurve: AppMotion.emphasized,
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 52,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        _touchedIndex =
                            response?.touchedSection?.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: [
                    for (var i = 0; i < entries.length; i++)
                      PieChartSectionData(
                        value: entries[i].value,
                        color: entries[i].key.colorFor(brightness),
                        radius: _touchedIndex == i ? 48 : 42,
                        title: '',
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (touched != null) ...[
                    Text(
                      l10n.categoryName(touched.key),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatter.format(touched.value),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ] else ...[
                    Text(
                      '${widget.breakdown.length}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      total > 0 ? l10n.categories : '',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
