import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/widgets/charts/category_legend_item.dart';
import 'package:gexpenses/presentation/widgets/charts/report_pie_chart.dart';
import 'package:gexpenses/presentation/widgets/charts/report_summary_card.dart';
import 'package:gexpenses/presentation/widgets/charts/report_view.dart';
import 'package:gexpenses/presentation/widgets/empty_state_widget.dart';
import 'package:gexpenses/presentation/widgets/expense_tile.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';

class CustomTab extends ConsumerWidget {
  const CustomTab({
    super.key,
    required this.start,
    required this.end,
    required this.onRangeChanged,
    this.onAddExpense,
  });

  final DateTime start;
  final DateTime end;
  final ValueChanged<DateTimeRange> onRangeChanged;
  final VoidCallback? onAddExpense;

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(start: start, end: end),
    );
    if (picked != null) {
      onRangeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reportAsync = ref.watch(
      customReportProvider(DateTimeRange(start: start, end: end)),
    );
    final now = DateTime.now();

    final presets = <String, DateTimeRange>{
      l10n.last7Days: DateTimeRange(
        start: now.subtract(const Duration(days: 6)),
        end: now,
      ),
      l10n.last30Days: DateTimeRange(
        start: now.subtract(const Duration(days: 29)),
        end: now,
      ),
      l10n.thisMonth: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      l10n.lastMonth: DateTimeRange(
        start: DateTime(now.year, now.month - 1, 1),
        end: DateTime(now.year, now.month, 0),
      ),
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
          child: Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              onTap: () => _pickRange(context),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(
                  AppConstants.spacing12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppConstants.spacing8),
                    Expanded(
                      child: Text(
                        '${l10n.formatShortDate(start)}'
                        ' – '
                        '${l10n.formatShortDate(end)}',
                        style: textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing8),
                    Text(
                      l10n.pickDateRange,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 4),
          child: Wrap(
            spacing: AppConstants.spacing8,
            runSpacing: AppConstants.spacing8,
            children: [
              for (final entry in presets.entries)
                ActionChip(
                  label: Text(entry.key),
                  onPressed: () => onRangeChanged(entry.value),
                ),
            ],
          ),
        ),
        Expanded(
          child: ReportAsyncView(
            value: reportAsync,
            onRetry: () => ref.invalidate(customReportProvider),
            builder: (context, report) => ListView(
              padding: reportContentPadding(context),
              children: [
                ReportSummaryCard(
                  title: l10n.totalSpent,
                  amount: report.totalSpent,
                  changePercent: report.changePercent,
                  trailing:
                      '${l10n.perDay}: ${CurrencyFormatter.format(report.dailyAverage)}'
                      ' · ${report.expenses.length} ${l10n.expensesCount}',
                ),
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
                const SizedBox(height: AppConstants.spacing16),
                if (report.expenses.isEmpty)
                  EmptyStateWidget(
                    title: l10n.noExpensesTitle,
                    subtitle: l10n.noExpensesSubtitle,
                    action: onAddExpense == null
                        ? null
                        : FilledButton.tonalIcon(
                            onPressed: onAddExpense,
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: Text(l10n.addExpense),
                          ),
                  )
                else
                  for (var i = 0; i < report.expenses.length; i++)
                    FadeSlideIn(
                      delay: AppMotion.stagger(i),
                      offset: 10,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          bottom: AppConstants.spacing8,
                        ),
                        child: ExpenseTile(expense: report.expenses[i]),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
