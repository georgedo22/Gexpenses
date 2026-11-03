import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/utils/amount_input.dart';
import 'package:gexpenses/core/utils/app_layout.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/data/models/budget.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
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
                      delay: Duration(milliseconds: i * 40),
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

    final statusColor = progress.isExceeded
        ? colorScheme.error
        : progress.isNearLimit
        ? const Color(0xFFD97706)
        : progress.category.color;

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
                  Icon(progress.category.icon, color: statusColor, size: 20),
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

/// Opens the budget editor. [initial] pre-selects the category and amount.
Future<void> showBudgetEditor(
  BuildContext context,
  WidgetRef ref, {
  BudgetProgress? initial,
}) async {
  final l10n = AppLocalizations.of(context);
  var category = initial?.category ?? ExpenseCategory.values.first;
  final amountController = TextEditingController(
    text: initial == null ? '' : initial.limit.toStringAsFixed(2),
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        scrollable: true,
        title: Text(l10n.setBudget),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: category,
              items: [
                for (final value in ExpenseCategory.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(l10n.categoryName(value)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => category = value);
              },
            ),
            const SizedBox(height: AppConstants.spacing12),
            TextField(
              controller: amountController,
              autofocus: initial == null,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [AmountInputFormatter()],
              decoration: InputDecoration(
                hintText: l10n.budgetFor,
                helperText: l10n.budgetRemoveHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final amount = parseAmountInput(amountController.text) ?? 0;
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(budgetServiceProvider)
                    .setBudget(category, amount < 0 ? 0 : amount);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                ref.invalidate(budgetProgressProvider);
                invalidateExpenseProviders(ref);
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.budgetUpdated)),
                );
              } catch (e) {
                debugPrint('Saving budget failed: $e');
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.errorGeneric)),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    ),
  );
}
