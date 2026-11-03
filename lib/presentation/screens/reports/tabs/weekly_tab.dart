import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/widgets/charts/report_bar_chart.dart';
import 'package:gexpenses/presentation/widgets/charts/report_summary_card.dart';
import 'package:gexpenses/presentation/widgets/charts/report_view.dart';
import 'package:gexpenses/presentation/widgets/period_navigator.dart';

class WeeklyTab extends ConsumerWidget {
  const WeeklyTab({
    super.key,
    required this.date,
    required this.onChanged,
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reportAsync = ref.watch(weeklyReportProvider(date));
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final isCurrentWeek =
        DateTime.now()
            .difference(
              DateTime(weekStart.year, weekStart.month, weekStart.day),
            )
            .inDays <
        7;

    return Column(
      children: [
        PeriodNavigator(
          label: l10n.weekOf(
            '${l10n.formatShortDate(weekStart)} – '
            '${l10n.formatShortDate(weekEnd)}',
          ),
          onPrevious: () => onChanged(date.subtract(const Duration(days: 7))),
          onNext: () => onChanged(date.add(const Duration(days: 7))),
          onLabelTap: () => _pickDate(context),
          canGoNext: !isCurrentWeek,
        ),
        Expanded(
          child: ReportAsyncView(
            value: reportAsync,
            onRetry: () => ref.invalidate(weeklyReportProvider),
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
                const SizedBox(height: AppConstants.spacing16),
                ReportBarChart(
                  values: [
                    for (var day = 1; day <= 7; day++)
                      report.dailyBreakdown[day] ?? 0.0,
                  ],
                  labels: [
                    for (var i = 0; i < 7; i++)
                      l10n.weekdayShort(
                        report.weekStart.add(Duration(days: i)),
                      ),
                  ],
                  semanticsLabel:
                      '${l10n.chartWeeklySpending}. '
                      '${l10n.totalSpent}: '
                      '${CurrencyFormatter.format(report.totalSpent)}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
