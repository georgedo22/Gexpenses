import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/widgets/charts/category_legend_item.dart';
import 'package:gexpenses/presentation/widgets/charts/report_pie_chart.dart';
import 'package:gexpenses/presentation/widgets/charts/report_summary_card.dart';
import 'package:gexpenses/presentation/widgets/charts/report_view.dart';
import 'package:gexpenses/presentation/widgets/period_navigator.dart';

class MonthlyTab extends ConsumerWidget {
  const MonthlyTab({
    super.key,
    required this.date,
    required this.onChanged,
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pickMonth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month + 1, 0),
    );
    // The picker returns a day; the tab works at month granularity.
    if (picked != null) onChanged(DateTime(picked.year, picked.month));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reportAsync = ref.watch(monthlyReportProvider(date));
    final now = DateTime.now();
    final isCurrentMonth = date.year == now.year && date.month == now.month;

    return Column(
      children: [
        PeriodNavigator(
          label: l10n.formatMonthYear(date),
          onPrevious: () => onChanged(DateTime(date.year, date.month - 1, 1)),
          onNext: () => onChanged(DateTime(date.year, date.month + 1, 1)),
          onLabelTap: () => _pickMonth(context),
          canGoNext: !isCurrentMonth,
        ),
        Expanded(
          child: ReportAsyncView(
            value: reportAsync,
            onRetry: () => ref.invalidate(monthlyReportProvider),
            builder: (context, report) => ListView(
              padding: reportContentPadding(context),
              children: [
                ReportSummaryCard(
                  title: l10n.totalSpent,
                  amount: report.totalSpent,
                  changePercent: report.changePercent,
                  trailing:
                      '${l10n.dailyAverage}: ${CurrencyFormatter.format(report.dailyAverage)}',
                ),
                if (report.totalIncome > 0) ...[
                  const SizedBox(height: AppConstants.spacing12),
                  CashFlowCard(income: report.totalIncome, net: report.netFlow),
                ],
                if (report.categoryBreakdown.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacing16),
                  ReportPieChart(
                    breakdown: report.categoryBreakdown,
                    semanticsLabel:
                        '${l10n.chartCategoryBreakdown}. '
                        '${l10n.totalSpent}: '
                        '${CurrencyFormatter.format(report.totalSpent)}',
                  ),
                  const SizedBox(height: AppConstants.spacing12),
                  for (final entry in report.categoryBreakdown.entries)
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
