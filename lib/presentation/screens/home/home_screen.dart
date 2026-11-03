import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/branding/brand_mark.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/app_layout.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/balance_providers.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/widgets/balance_card.dart';
import 'package:gexpenses/presentation/widgets/empty_state_widget.dart';
import 'package:gexpenses/presentation/widgets/expense_tile.dart';
import 'package:gexpenses/presentation/widgets/loading_skeleton.dart';
import 'package:gexpenses/presentation/widgets/month_summary_card.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.onAddExpense, this.onViewAllExpenses});

  /// Opens the add-expense flow from the empty state.
  final VoidCallback? onAddExpense;

  /// Opens the full, searchable expense history.
  final VoidCallback? onViewAllExpenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recentAsync = ref.watch(recentExpensesProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          invalidateExpenseProviders(ref);
          // Wait until the dashboard data has actually reloaded so the
          // refresh indicator reflects real work instead of vanishing early.
          await Future.wait([
            ref.refresh(recentExpensesProvider.future),
            ref.refresh(currentBalanceProvider.future),
            ref.refresh(initialBalanceProvider.future),
            ref.refresh(isLowBalanceProvider.future),
            ref.refresh(monthSummaryProvider.future),
          ]);
        },
        child: ResponsiveContent(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppLayout.pagePadding(
              context,
            ).add(const EdgeInsetsDirectional.only(top: 8, bottom: 96)),
            children: [
              const FadeSlideIn(child: _HomeHeader()),
              const SizedBox(height: AppConstants.spacing20),
              const FadeSlideIn(
                delay: Duration(milliseconds: 60),
                child: BalanceCard(),
              ),
              const SizedBox(height: AppConstants.spacing16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 90),
                child: MonthSummaryCard(),
              ),
              const SizedBox(height: AppConstants.spacing24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 110),
                child: _SectionHeader(
                  title: l10n.recentExpenses,
                  actionLabel: onViewAllExpenses == null ? null : l10n.viewAll,
                  onAction: onViewAllExpenses,
                ),
              ),
              const SizedBox(height: AppConstants.spacing12),
              recentAsync.when(
                loading: () => const FadeSlideIn(
                  delay: Duration(milliseconds: 150),
                  child: LoadingSkeleton(itemCount: 4),
                ),
                error: (error, _) => FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  child: Column(
                    children: [
                      EmptyStateWidget(
                        icon: Icons.cloud_off_rounded,
                        title: l10n.errorTitle,
                        subtitle: l10n.errorGeneric,
                      ),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(recentExpensesProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: EmptyStateWidget(
                        icon: Icons.savings_outlined,
                        title: l10n.noExpensesTitle,
                        subtitle: l10n.noExpensesSubtitle,
                        action: onAddExpense == null
                            ? null
                            : FilledButton.tonalIcon(
                                onPressed: onAddExpense,
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: Text(l10n.addExpense),
                              ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < expenses.length; i++)
                        FadeSlideIn(
                          delay: AppMotion.stagger(i),
                          offset: 12,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              bottom: AppConstants.spacing8,
                            ),
                            child: ExpenseTile(expense: expenses[i]),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        const BrandMark(size: 48),
        const SizedBox(width: AppConstants.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appName,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.headerDate(DateTime.now()),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppConstants.spacing8,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}
