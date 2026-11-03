import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/utils/app_layout.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/screens/reports/tabs/custom_tab.dart';
import 'package:gexpenses/presentation/screens/reports/tabs/daily_tab.dart';
import 'package:gexpenses/presentation/screens/reports/tabs/monthly_tab.dart';
import 'package:gexpenses/presentation/screens/reports/tabs/weekly_tab.dart';
import 'package:gexpenses/presentation/screens/reports/tabs/yearly_tab.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';

/// Reports shell: period tabs over the shared report content widgets.
///
/// Each tab reads its data from a `FutureProvider.family` in
/// `expense_providers.dart`, so rebuilds never re-fetch and mutations refresh
/// every visible report through `invalidateExpenseProviders`.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, this.onAddExpense});

  /// Opens the add-expense flow from empty report states.
  final VoidCallback? onAddExpense;

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
                    Icon(Icons.insights_rounded, color: colorScheme.primary),
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
                    DailyTab(
                      date: _selectedDate,
                      onChanged: (d) => setState(() => _selectedDate = d),
                      onAddExpense: widget.onAddExpense,
                    ),
                    WeeklyTab(
                      date: _selectedDate,
                      onChanged: (d) => setState(() => _selectedDate = d),
                    ),
                    MonthlyTab(
                      date: _selectedDate,
                      onChanged: (d) => setState(() => _selectedDate = d),
                    ),
                    YearlyTab(
                      year: _selectedDate.year,
                      onChanged: (y) => setState(
                        () => _selectedDate = DateTime(y, _selectedDate.month),
                      ),
                    ),
                    CustomTab(
                      start: _rangeStart,
                      end: _rangeEnd,
                      onRangeChanged: (range) => setState(() {
                        _rangeStart = range.start;
                        _rangeEnd = range.end;
                      }),
                      onAddExpense: widget.onAddExpense,
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
