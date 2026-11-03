import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_colors.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/app_layout.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/data/models/report_data.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/widgets/animated_amount.dart';
import 'package:gexpenses/presentation/widgets/category_icon.dart';
import 'package:gexpenses/presentation/widgets/empty_state_widget.dart';
import 'package:gexpenses/presentation/widgets/expense_tile.dart';
import 'package:gexpenses/presentation/widgets/loading_skeleton.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';
import 'package:gexpenses/presentation/widgets/period_navigator.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  DateTime _rangeStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _rangeEnd = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 12),
              child: FadeSlideIn(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.reports,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ),
                    Icon(
                      Icons.insights_rounded,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsetsDirectional.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: isDark ? 0.35 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: colorScheme.primary.withValues(
                      alpha: isDark ? 0.3 : 0.14,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusSmall,
                    ),
                  ),
                  overlayColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(text: l10n.daily),
                    Tab(text: l10n.weekly),
                    Tab(text: l10n.monthly),
                    Tab(text: l10n.yearly),
                    Tab(text: l10n.custom),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ResponsiveContent(
                maxWidth: AppLayout.wideContentMaxWidth,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DailyTab(
                      date: _selectedDate,
                      onChanged: (d) => setState(() => _selectedDate = d),
                    ),
                    _WeeklyTab(
                      date: _selectedDate,
                      onChanged: (d) => setState(() => _selectedDate = d),
                    ),
                    _MonthlyTab(
                      date: _selectedDate,
                      onChanged: (d) => setState(() => _selectedDate = d),
                    ),
                    _YearlyTab(
                      year: _selectedDate.year,
                      onChanged: (y) => setState(
                        () => _selectedDate = DateTime(y, _selectedDate.month),
                      ),
                    ),
                    _CustomTab(
                      start: _rangeStart,
                      end: _rangeEnd,
                      onRangeChanged: (range) => setState(() {
                        _rangeStart = range.start;
                        _rangeEnd = range.end;
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SHARED WIDGETS ─────────────────────────────────────────────────────

EdgeInsetsGeometry _contentPadding(BuildContext context) =>
    AppLayout.pagePadding(context).add(
      const EdgeInsetsDirectional.only(top: 8, bottom: 24),
    );

/// Rounded surface used for charts and secondary report content.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsetsDirectional.all(AppConstants.spacing12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: child,
    );
  }
}

/// Handles loading, empty and loaded states for every report period.
class _ReportView<T> extends StatelessWidget {
  const _ReportView({
    required this.reportKey,
    required this.future,
    required this.emptyLabel,
    required this.builder,
  });

  final String reportKey;
  final Future<T> future;
  final String emptyLabel;
  final Widget Function(BuildContext context, T report) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      key: ValueKey(reportKey),
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            padding: _contentPadding(context),
            children: const [
              LoadingSkeleton(itemCount: 3, itemHeight: 96),
            ],
          );
        }
        final report = snapshot.data;
        if (report == null) {
          return EmptyStateWidget(title: emptyLabel);
        }
        return FadeSlideIn(
          key: ValueKey(reportKey),
          child: builder(context, report),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.changePercent,
    this.trailing,
  });

  final String title;
  final double amount;
  final double? changePercent;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final up = (changePercent ?? 0) >= 0;
    final trendColor = up
        ? colorScheme.error
        : (isDark ? AppColors.successDark : AppColors.successLight);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: isDark ? 0.24 : 0.12),
            colorScheme.tertiary.withValues(alpha: isDark ? 0.10 : 0.05),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      padding: const EdgeInsetsDirectional.all(AppConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing8),
                    AnimatedAmount(
                      value: amount,
                      style: textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.14),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          if (changePercent != null) ...[
            const SizedBox(height: AppConstants.spacing12),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppConstants.spacing8,
                vertical: AppConstants.spacing4,
              ),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusSmall,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    up
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 16,
                    color: trendColor,
                  ),
                  const SizedBox(width: AppConstants.spacing4),
                  Flexible(
                    child: Text(
                      '${up ? '+' : ''}'
                      '${changePercent!.toStringAsFixed(1)}% '
                      '${l10n.vsPreviousPeriod}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: AppConstants.spacing8),
            Text(
              trailing!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  const _BarChartWidget({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

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

    return _Panel(
      child: SizedBox(
        height: height,
        child: BarChart(
          swapAnimationDuration: AppMotion.resolve(context, AppMotion.slow),
          swapAnimationCurve: AppMotion.emphasized,
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue <= 0 ? 1.0 : maxValue * 1.2,
            barTouchData: BarTouchData(enabled: false),
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
    );
  }
}

class _PieChartWidget extends StatelessWidget {
  const _PieChartWidget({required this.breakdown});

  final Map<ExpenseCategory, double> breakdown;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = breakdown.values.fold<double>(0, (sum, v) => sum + v);

    return _Panel(
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
                sections: [
                  for (final entry in breakdown.entries)
                    PieChartSectionData(
                      value: entry.value,
                      color: entry.key.color,
                      radius: 42,
                      title: '',
                    ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${breakdown.length}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  total > 0 ? 'Categories' : '',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryLegendItem extends StatelessWidget {
  const _CategoryLegendItem({
    required this.category,
    required this.amount,
    required this.total,
  });

  final ExpenseCategory category;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final percent = total > 0 ? (amount / total * 100) : 0.0;
    final color = category.color;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: AppConstants.spacing8,
      ),
      child: Row(
        children: [
          CategoryIcon(category: category, size: 36),
          const SizedBox(width: AppConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.label,
                        style: textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing8),
                    Text(
                      CurrencyFormatter.format(amount),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing4),
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: (percent / 100).clamp(0.0, 1.0),
                        ),
                        duration: AppMotion.resolve(
                          context,
                          AppMotion.countUp,
                        ),
                        curve: AppMotion.emphasized,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(3),
                          backgroundColor: color.withValues(alpha: 0.14),
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing8),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${percent.toStringAsFixed(0)}%',
                        textAlign: TextAlign.end,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── TABS ───────────────────────────────────────────────────────────────

class _DailyTab extends ConsumerWidget {
  const _DailyTab({required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final service = ref.watch(reportServiceProvider);
    // Re-run the report whenever any mutation happens elsewhere in the app.
    final version = ref.watch(reportsVersionProvider);
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return Column(
      children: [
        PeriodNavigator(
          label: DateFormat('EEE, MMM d, yyyy').format(date),
          onPrevious: () => onChanged(date.subtract(const Duration(days: 1))),
          onNext: () => onChanged(date.add(const Duration(days: 1))),
          canGoNext: !isToday,
        ),
        Expanded(
          child: _ReportView<DailyReport>(
            reportKey: 'daily|$date|$version',
            future: service.getDailyReport(date),
            emptyLabel: l10n.noData,
            builder: (context, report) => ListView(
              padding: _contentPadding(context),
              children: [
                _SummaryCard(
                  title: l10n.totalSpent,
                  amount: report.totalSpent,
                  changePercent: report.changePercent,
                ),
                const SizedBox(height: AppConstants.spacing16),
                if (report.expenses.isEmpty)
                  EmptyStateWidget(
                    title: l10n.noExpensesTitle,
                    subtitle: l10n.noExpensesSubtitle,
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

class _WeeklyTab extends ConsumerWidget {
  const _WeeklyTab({required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final service = ref.watch(reportServiceProvider);
    // Re-run the report whenever any mutation happens elsewhere in the app.
    final version = ref.watch(reportsVersionProvider);
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
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
          label:
              'Week of ${DateFormat('MMM d').format(weekStart)} – ${DateFormat('MMM d, yyyy').format(weekStart.add(const Duration(days: 6)))}',
          onPrevious: () => onChanged(date.subtract(const Duration(days: 7))),
          onNext: () => onChanged(date.add(const Duration(days: 7))),
          canGoNext: !isCurrentWeek,
        ),
        Expanded(
          child: _ReportView<WeeklyReport>(
            reportKey: 'weekly|$date|$version',
            future: service.getWeeklyReport(date),
            emptyLabel: l10n.noData,
            builder: (context, report) => ListView(
              padding: _contentPadding(context),
              children: [
                _SummaryCard(
                  title: l10n.totalSpent,
                  amount: report.totalSpent,
                  changePercent: report.changePercent,
                  trailing:
                      '${l10n.dailyAverage}: ${CurrencyFormatter.format(report.dailyAverage)}',
                ),
                const SizedBox(height: AppConstants.spacing16),
                _BarChartWidget(
                  values: [
                    for (var day = 1; day <= 7; day++)
                      report.dailyBreakdown[day] ?? 0.0,
                  ],
                  labels: const [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthlyTab extends ConsumerWidget {
  const _MonthlyTab({required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final service = ref.watch(reportServiceProvider);
    // Re-run the report whenever any mutation happens elsewhere in the app.
    final version = ref.watch(reportsVersionProvider);
    final now = DateTime.now();
    final isCurrentMonth = date.year == now.year && date.month == now.month;

    return Column(
      children: [
        PeriodNavigator(
          label: DateFormat('MMMM yyyy').format(date),
          onPrevious: () => onChanged(DateTime(date.year, date.month - 1, 1)),
          onNext: () => onChanged(DateTime(date.year, date.month + 1, 1)),
          canGoNext: !isCurrentMonth,
        ),
        Expanded(
          child: _ReportView<MonthlyReport>(
            reportKey: 'monthly|$date|$version',
            future: service.getMonthlyReport(date),
            emptyLabel: l10n.noData,
            builder: (context, report) => ListView(
              padding: _contentPadding(context),
              children: [
                _SummaryCard(
                  title: l10n.totalSpent,
                  amount: report.totalSpent,
                  changePercent: report.changePercent,
                  trailing:
                      '${l10n.dailyAverage}: ${CurrencyFormatter.format(report.dailyAverage)}',
                ),
                if (report.categoryBreakdown.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacing16),
                  _PieChartWidget(breakdown: report.categoryBreakdown),
                  const SizedBox(height: AppConstants.spacing12),
                  for (final entry in report.categoryBreakdown.entries)
                    _CategoryLegendItem(
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

class _YearlyTab extends ConsumerWidget {
  const _YearlyTab({required this.year, required this.onChanged});

  final int year;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final service = ref.watch(reportServiceProvider);
    // Re-run the report whenever any mutation happens elsewhere in the app.
    final version = ref.watch(reportsVersionProvider);
    final isCurrentYear = year == DateTime.now().year;

    return Column(
      children: [
        PeriodNavigator(
          label: year.toString(),
          onPrevious: () => onChanged(year - 1),
          onNext: () => onChanged(year + 1),
          canGoNext: !isCurrentYear,
        ),
        Expanded(
          child: _ReportView<YearlyReport>(
            reportKey: 'yearly|$year|$version',
            future: service.getYearlyReport(year),
            emptyLabel: l10n.noData,
            builder: (context, report) => ListView(
              padding: _contentPadding(context),
              children: [
                _SummaryCard(
                  title: l10n.totalSpent,
                  amount: report.totalSpent,
                  changePercent: null,
                  trailing:
                      '${l10n.monthlyAverage}: ${CurrencyFormatter.format(report.monthlyAverage)}',
                ),
                const SizedBox(height: AppConstants.spacing16),
                _BarChartWidget(
                  values: [
                    for (var month = 1; month <= 12; month++)
                      report.monthlyBreakdown[month] ?? 0.0,
                  ],
                  labels: const [
                    'J',
                    'F',
                    'M',
                    'A',
                    'M',
                    'J',
                    'J',
                    'A',
                    'S',
                    'O',
                    'N',
                    'D',
                  ],
                ),
                if (report.topCategories.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacing24),
                  for (final entry in report.topCategories.entries.take(5))
                    _CategoryLegendItem(
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

// ── CUSTOM RANGE TAB ───────────────────────────────────────────────────

class _CustomTab extends ConsumerWidget {
  const _CustomTab({
    required this.start,
    required this.end,
    required this.onRangeChanged,
  });

  final DateTime start;
  final DateTime end;
  final ValueChanged<DateTimeRange> onRangeChanged;

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
    final service = ref.watch(reportServiceProvider);
    // Re-run the report whenever any mutation happens elsewhere in the app.
    final version = ref.watch(reportsVersionProvider);
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
                        '${DateFormat('MMM d, yyyy').format(start)}'
                        ' – '
                        '${DateFormat('MMM d, yyyy').format(end)}',
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
          child: _ReportView<CustomReport>(
            reportKey: 'custom|$start|$end|$version',
            future: service.getCustomReport(start, end),
            emptyLabel: l10n.noData,
            builder: (context, report) => ListView(
              padding: _contentPadding(context),
              children: [
                _SummaryCard(
                  title: l10n.totalSpent,
                  amount: report.totalSpent,
                  changePercent: report.changePercent,
                  trailing:
                      '${l10n.perDay}: ${CurrencyFormatter.format(report.dailyAverage)}'
                      ' · ${report.expenses.length} ${l10n.expensesCount}',
                ),
                if (report.categoryBreakdown.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacing16),
                  _PieChartWidget(breakdown: report.categoryBreakdown),
                  const SizedBox(height: AppConstants.spacing12),
                  for (final entry in report.categoryBreakdown.entries)
                    _CategoryLegendItem(
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
