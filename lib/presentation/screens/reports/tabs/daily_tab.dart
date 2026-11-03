import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/widgets/charts/report_summary_card.dart';
import 'package:gexpenses/presentation/widgets/charts/report_view.dart';
import 'package:gexpenses/presentation/widgets/empty_state_widget.dart';
import 'package:gexpenses/presentation/widgets/expense_tile.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';
import 'package:gexpenses/presentation/widgets/period_navigator.dart';

class DailyTab extends ConsumerWidget {
  const DailyTab({
    super.key,
    required this.date,
    required this.onChanged,
    this.onAddExpense,
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onAddExpense;

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
    final reportAsync = ref.watch(dailyReportProvider(date));
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return Column(
      children: [
        PeriodNavigator(
          label: l10n.formatDate(date),
          onPrevious: () => onChanged(date.subtract(const Duration(days: 1))),
          onNext: () => onChanged(date.add(const Duration(days: 1))),
          onLabelTap: () => _pickDate(context),
          canGoNext: !isToday,
        ),
        Expanded(
          child: ReportAsyncView(
            value: reportAsync,
            onRetry: () => ref.invalidate(dailyReportProvider),
            builder: (context, report) => ListView(
              padding: reportContentPadding(context),
              children: [
                ReportSummaryCard(
                  title: l10n.totalSpent,
                  amount: report.totalSpent,
                  changePercent: report.changePercent,
                ),
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
