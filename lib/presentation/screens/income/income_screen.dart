import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/utils/app_layout.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/data/models/income.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/screens/income/income_editor_dialog.dart';
import 'package:gexpenses/presentation/widgets/empty_state_widget.dart';
import 'package:gexpenses/presentation/widgets/loading_skeleton.dart';
import 'package:gexpenses/presentation/widgets/month_summary_card.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';

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
              const FadeSlideIn(child: MonthSummaryCard()),
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
                                  l10n.formatDate(incomes[i].dateTime),
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
