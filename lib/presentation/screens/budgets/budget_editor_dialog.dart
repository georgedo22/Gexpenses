import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/utils/amount_input.dart';
import 'package:gexpenses/data/models/budget.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';

/// Opens the budget editor. [initial] pre-selects the category and amount.
Future<void> showBudgetEditor(
  BuildContext context,
  WidgetRef ref, {
  BudgetProgress? initial,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) =>
        _BudgetEditorDialog(ref: ref, initial: initial),
  );
}

/// The dialog owns its text controller and disposes it with its own State,
/// so nothing leaks when the route is popped.
class _BudgetEditorDialog extends ConsumerStatefulWidget {
  const _BudgetEditorDialog({required this.ref, this.initial});

  // The opener's ref stays valid for the lifetime of the dialog because the
  // calling screen remains mounted below the route.
  final WidgetRef ref;
  final BudgetProgress? initial;

  @override
  ConsumerState<_BudgetEditorDialog> createState() =>
      _BudgetEditorDialogState();
}

class _BudgetEditorDialogState extends ConsumerState<_BudgetEditorDialog> {
  late final TextEditingController _amountController;
  late ExpenseCategory _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initial?.category ?? ExpenseCategory.values.first;
    _amountController = TextEditingController(
      text: widget.initial == null ? '' : widget.initial!.limit.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final amount = parseAmountInput(_amountController.text) ?? 0;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(budgetServiceProvider)
          .setBudget(_category, amount < 0 ? 0 : amount);
      if (mounted) Navigator.of(context).pop();
      invalidateExpenseProviders(widget.ref);
      messenger.showSnackBar(SnackBar(content: Text(l10n.budgetUpdated)));
    } catch (e) {
      debugPrint('Saving budget failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      scrollable: true,
      title: Text(l10n.setBudget),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ExpenseCategory>(
            initialValue: _category,
            items: [
              for (final value in ExpenseCategory.values)
                DropdownMenuItem(
                  value: value,
                  child: Text(l10n.categoryName(value)),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: AppConstants.spacing12),
          TextField(
            controller: _amountController,
            autofocus: widget.initial == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
