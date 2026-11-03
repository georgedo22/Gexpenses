import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/utils/amount_input.dart';
import 'package:gexpenses/core/utils/app_layout.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/core/utils/date_helper.dart';
import 'package:gexpenses/data/models/income.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/widgets/empty_state_widget.dart';
import 'package:gexpenses/presentation/widgets/loading_skeleton.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';

/// Shows an add/edit income dialog. Pass [income] to edit an existing entry.
Future<void> showIncomeEditor(
  BuildContext context,
  WidgetRef ref, {
  Income? income,
}) async {
  final l10n = AppLocalizations.of(context);
  final amountController = TextEditingController(
    text: income == null ? '' : income.amount.toStringAsFixed(2),
  );
  final descriptionController = TextEditingController(
    text: income?.description ?? '',
  );
  final isEditing = income != null;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      scrollable: true,
      title: Text(isEditing ? l10n.editIncome : l10n.addIncome),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AmountInputFormatter()],
            decoration: InputDecoration(hintText: l10n.incomeAmount),
          ),
          const SizedBox(height: AppConstants.spacing12),
          TextField(
            controller: descriptionController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l10n.description),
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
            final amount = parseAmountInput(amountController.text);
            if (amount == null || amount <= 0) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
              return;
            }
            final description = descriptionController.text.trim();
            final service = ref.read(expenseServiceProvider);
            final messenger = ScaffoldMessenger.of(context);

            try {
              if (isEditing) {
                await service.updateIncome(
                  income,
                  income.copyWith(
                    amount: amount,
                    description: description.isEmpty
                        ? income.description
                        : description,
                  ),
                );
              } else {
                await service.addIncome(
                  amount,
                  description.isEmpty ? l10n.addIncome : description,
                );
              }
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              invalidateExpenseProviders(ref);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    isEditing ? l10n.incomeUpdated : l10n.incomeAdded,
                  ),
                ),
              );
            } catch (e) {
              debugPrint('Saving income failed: $e');
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.errorGeneric)),
              );
            }
          },
          child: Text(isEditing ? l10n.update : l10n.save),
        ),
      ],
    ),
  );
  // Not disposed on purpose: showDialog completes before the exit animation
  // finishes, and disposing then crashes the still-mounted TextFields.
}

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Income income,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteIncome),
        content: Text(l10n.deleteIncomeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(expenseServiceProvider).deleteIncome(income);
      invalidateExpenseProviders(ref);
      messenger.showSnackBar(SnackBar(content: Text(l10n.incomeDeleted)));
    } catch (e) {
      debugPrint('Deleting income failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final incomesAsync = ref.watch(incomesProvider);
    final summaryAsync = ref.watch(monthSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.incomeHistory)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showIncomeEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addIncome),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: ListView(
            padding: AppLayout.pagePadding(
              context,
            ).add(const EdgeInsetsDirectional.only(top: 8, bottom: 96)),
            children: [
              FadeSlideIn(
                child: summaryAsync.when(
                  loading: () => const SizedBox(
                    height: 96,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (summary) => Card(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(
                        AppConstants.spacing16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryCell(
                              label: l10n.incomeThisMonth,
                              value: summary.income,
                              color: colorScheme.primary,
                            ),
                          ),
                          Expanded(
                            child: _SummaryCell(
                              label: l10n.totalSpent,
                              value: summary.spent,
                              color: colorScheme.error,
                            ),
                          ),
                          Expanded(
                            child: _SummaryCell(
                              label: l10n.netFlowThisMonth,
                              value: summary.net,
                              color: summary.net >= 0
                                  ? colorScheme.primary
                                  : colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacing20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Text(
                  l10n.incomeHistory,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacing12),
              incomesAsync.when(
                loading: () => const LoadingSkeleton(itemCount: 3),
                error: (_, _) => EmptyStateWidget(
                  icon: Icons.cloud_off_rounded,
                  title: l10n.errorTitle,
                  subtitle: l10n.errorGeneric,
                  action: TextButton.icon(
                    onPressed: () => ref.invalidate(incomesProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.retry),
                  ),
                ),
                data: (incomes) {
                  if (incomes.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.savings_outlined,
                      title: l10n.noIncomes,
                      subtitle: l10n.noIncomesSubtitle,
                      action: FilledButton.tonalIcon(
                        onPressed: () => showIncomeEditor(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(l10n.addIncome),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (var i = 0; i < incomes.length; i++)
                        FadeSlideIn(
                          delay: Duration(milliseconds: 60 + i * 25),
                          offset: 10,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              bottom: AppConstants.spacing8,
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.savings_rounded,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                title: Text(
                                  incomes[i].description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  DateHelper.fullDate(incomes[i].dateTime),
                                ),
                                trailing: Text(
                                  '+${CurrencyFormatter.format(incomes[i].amount)}',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                onTap: () => showIncomeEditor(
                                  context,
                                  ref,
                                  income: incomes[i],
                                ),
                                onLongPress: () =>
                                    _confirmDelete(context, ref, incomes[i]),
                              ),
                            ),
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

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppConstants.spacing4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            CurrencyFormatter.format(value),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
