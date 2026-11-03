import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/utils/app_layout.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/data/models/budget.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/screens/budgets/budget_editor_dialog.dart';
import 'package:gexpenses/presentation/widgets/empty_state_widget.dart';
import 'package:gexpenses/presentation/widgets/loading_skeleton.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';

/// Monthly per-category limits with live progress for the current month.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final budgetAsync = ref.watch(budgetProgressProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgets)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showBudgetEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.setBudget),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: budgetAsync.when(
            loading: () => const Padding(
              padding: EdgeInsetsDirectional.all(AppConstants.spacing16),
              child: LoadingSkeleton(itemCount: 4),
            ),
            error: (_, _) => EmptyStateWidget(
              icon: Icons.cloud_off_rounded,
              title: l10n.errorTitle,
              subtitle: l10n.errorGeneric,
              action: TextButton.icon(
                onPressed: () => ref.invalidate(budgetProgressProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retry),
              ),
            ),
            data: (budgets) {
              if (budgets.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.pie_chart_outline_rounded,
                  title: l10n.noBudgets,
                  subtitle: l10n.noBudgetsSubtitle,
                  action: FilledButton.tonalIcon(
                    onPressed: () => showBudgetEditor(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(l10n.setBudget),
                  ),
                );
              }

              return ListView(
                padding: AppLayout.pagePadding(
                  context,
                ).add(const EdgeInsetsDirectional.only(top: 8, bottom: 96)),
                children: [
                  for (var i = 0; i < budgets.length; i++)
                    FadeSlideIn(
                      delay: AppMotion.stagger(i, step: 40),
                      offset: 10,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          bottom: AppConstants.spacing12,
                        ),
                        child: _BudgetCard(
                          progress: budgets[i],
                          onTap: () => showBudgetEditor(
                            context,
                            ref,
                            initial: budgets[i],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.progress, required this.onTap});

  final BudgetProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = progress.category.colorFor(
      Theme.of(context).brightness,
    );

    final statusColor = progress.isExceeded
        ? colorScheme.error
        : progress.isNearLimit
        ? const Color(0xFFD97706)
        : categoryColor;

    final status = progress.isExceeded
        ? l10n.overBudget
        : progress.isNearLimit
        ? l10n.nearLimit
        : null;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppConstants.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Semantics(
                    label: l10n.categoryName(progress.category),
                    excludeSemantics: true,
                    child: Icon(progress.category.icon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: AppConstants.spacing8),
                  Expanded(
                    child: Text(
                      l10n.categoryName(progress.category),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (status != null)
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppConstants.spacing8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusSmall,
                        ),
                      ),
                      child: Text(
                        status,
                        style: textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.spacing12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress.ratio,
                  minHeight: 8,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: AppConstants.spacing8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${CurrencyFormatter.format(progress.spent)} '
                      '${l10n.spentLabel} / '
                      '${CurrencyFormatter.format(progress.limit)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    progress.remaining >= 0
                        ? '${CurrencyFormatter.format(progress.remaining)} '
                              '${l10n.remainingLabel}'
                        : '-${CurrencyFormatter.format(-progress.remaining)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
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
