import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/utils/amount_input.dart';
import 'package:gexpenses/data/models/income.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';

/// Shows an add/edit income dialog. Pass [income] to edit an existing entry.
Future<void> showIncomeEditor(
  BuildContext context,
  WidgetRef ref, {
  Income? income,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _IncomeEditorDialog(ref: ref, income: income),
  );
}

/// The dialog owns its text controllers and disposes them with its own
/// State, so nothing leaks when the route is popped.
class _IncomeEditorDialog extends ConsumerStatefulWidget {
  const _IncomeEditorDialog({required this.ref, this.income});

  // The opener's ref stays valid for the lifetime of the dialog because the
  // calling screen remains mounted below the route.
  final WidgetRef ref;
  final Income? income;

  @override
  ConsumerState<_IncomeEditorDialog> createState() =>
      _IncomeEditorDialogState();
}

class _IncomeEditorDialogState extends ConsumerState<_IncomeEditorDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  bool get _isEditing => widget.income != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.income == null ? '' : widget.income!.amount.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.income?.description ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final amount = parseAmountInput(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
      return;
    }
    final description = _descriptionController.text.trim();
    final service = ref.read(expenseServiceProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final income = widget.income;
      if (_isEditing) {
        await service.updateIncome(
          income!,
          income.copyWith(
            amount: amount,
            description: description.isEmpty ? income.description : description,
          ),
        );
      } else {
        await service.addIncome(
          amount,
          description.isEmpty ? l10n.addIncome : description,
        );
      }
      if (mounted) Navigator.of(context).pop();
      invalidateExpenseProviders(widget.ref);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing ? l10n.incomeUpdated : l10n.incomeAdded),
        ),
      );
    } catch (e) {
      debugPrint('Saving income failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      scrollable: true,
      title: Text(_isEditing ? l10n.editIncome : l10n.addIncome),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AmountInputFormatter()],
            decoration: InputDecoration(hintText: l10n.incomeAmount),
          ),
          const SizedBox(height: AppConstants.spacing12),
          TextField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l10n.description),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(_isEditing ? l10n.update : l10n.save)),
      ],
    );
  }
}
