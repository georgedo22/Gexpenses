import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/widgets/charts/category_legend_item.dart';
import 'package:gexpenses/presentation/widgets/charts/report_bar_chart.dart';
import 'package:gexpenses/presentation/widgets/charts/report_summary_card.dart';
import 'package:gexpenses/presentation/widgets/charts/report_view.dart';
import 'package:gexpenses/presentation/widgets/period_navigator.dart';

class YearlyTab extends ConsumerWidget {
  const YearlyTab({
    super.key,
    required this.year,
    required this.onChanged,
  });

  final int year;
  final ValueChanged<int> onChanged;

  Future<void> _pickYear(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(year),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, 12, 31),
    );
    // The picker returns a day; the tab works at year granularity.
    if (picked != null) onChanged(picked.year);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reportAsync = ref.watch(yearlyReportProvider(year));
    final isCurrentYear = year == DateTime.now().year;

    return Column(
      children: [
        PeriodNavigator(
          label: year.toString(),
          onPrevious: () => onChanged(year - 1),
          onNext: () => onChanged(year + 1),
          onLabelTap: () => _pickYear(context),
          canGoNext: !isCurrentYear,
        ),
        Expanded(
          child: ReportAsyncView(
            value: reportAsync,
            onRetry: () => ref.invalidate(yearlyReportProvider),
            builder: (context, report) => ListView(
              padding: reportContentPadding(context),
              children: [
                ReportSummaryCard(
                  title: l10n.totalSpent,
                  amount: report.totalSpent,
                  changePercent: null,
                  trailing:
                      '${l10n.monthlyAverage}: ${CurrencyFormatter.format(report.monthlyAverage)}',
                ),
                const SizedBox(height: AppConstants.spacing16),
                ReportBarChart(
                  values: [
                    for (var month = 1; month <= 12; month++)
                      report.monthlyBreakdown[month] ?? 0.0,
                  ],
                  labels: [
                    for (var month = 1; month <= 12; month++)
                      l10n.monthInitial(month),
                  ],
                  semanticsLabel:
                      '${l10n.chartMonthlySpending}. '
                      '${l10n.totalSpent}: '
                      '${CurrencyFormatter.format(report.totalSpent)}',
                ),
                if (report.topCategories.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacing24),
                  for (final entry in report.topCategories.entries.take(5))
                    CategoryLegendItem(
                      category: entry.key,
                      amount: entry.value,
                      total: report.totalSpent,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
