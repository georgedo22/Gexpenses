import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/data/models/expense.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/screens/add_expense/add_expense_screen.dart';
import 'package:gexpenses/presentation/widgets/category_icon.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';

class ExpenseTile extends ConsumerWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
  });

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final expenseService = ref.read(expenseServiceProvider);
    final radius = BorderRadius.circular(AppConstants.borderRadius);

    return Dismissible(
      key: ValueKey(expense.id ?? expense.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppConstants.spacing24),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: radius,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      // Swipe deletes immediately and offers undo in the snackbar — the
      // standard Material pattern (no confirmation dialog on top of it).
      onDismissed: (_) async {
        final deletedExpense = expense;
        String? errorMessage;
        try {
          await expenseService.deleteExpense(deletedExpense);
          invalidateExpenseProviders(ref);
        } catch (e) {
          debugPrint('Deleting expense failed: $e');
          errorMessage = l10n.errorGeneric;
        }

        if (errorMessage != null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
          return;
        }

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.expenseDeleted),
            action: SnackBarAction(
              label: l10n.cancel,
              onPressed: () async {
                try {
                  await expenseService.addExpense(deletedExpense);
                  invalidateExpenseProviders(ref);
                } catch (e) {
                  debugPrint('Restoring expense failed: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.errorGeneric)),
                    );
                  }
                }
              },
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Pressable(
          borderRadius: radius,
          onTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => AddExpenseScreen(expense: expense),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppConstants.spacing16,
              vertical: AppConstants.spacing12,
            ),
            child: Row(
              children: [
                CategoryIcon(category: expense.category),
                const SizedBox(width: AppConstants.spacing12),
                Expanded(
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${l10n.categoryName(expense.category)} • '
                          '${l10n.relativeDate(expense.dateTime)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacing8),
                Flexible(
                  child: Text(
                    '- ${CurrencyFormatter.format(expense.amount)}',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.error,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
