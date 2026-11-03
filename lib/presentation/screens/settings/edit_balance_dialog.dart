import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/utils/amount_input.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/balance_providers.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';

/// Dialog for manually setting the current balance.
///
/// The dialog owns its text controller and disposes it with its own State,
/// so nothing leaks when the route is popped.
Future<void> showEditBalanceDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _EditBalanceDialog(ref: ref),
  );
}

class _EditBalanceDialog extends ConsumerStatefulWidget {
  const _EditBalanceDialog({required this.ref});

  // The opener's ref stays valid for the lifetime of the dialog because the
  // calling screen remains mounted below the route.
  final WidgetRef ref;

  @override
  ConsumerState<_EditBalanceDialog> createState() => _EditBalanceDialogState();
}

class _EditBalanceDialogState extends ConsumerState<_EditBalanceDialog> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final amount = parseAmountInput(_controller.text);
    final messenger = ScaffoldMessenger.of(context);
    if (amount == null || amount < 0) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
      return;
    }
    try {
      // Only adjust the CURRENT balance so the recorded expense history
      // stays intact.
      await ref.read(balanceRepositoryProvider).updateCurrentBalance(amount);
      if (mounted) Navigator.of(context).pop();
      invalidateExpenseProviders(widget.ref);
      messenger.showSnackBar(SnackBar(content: Text(l10n.balanceUpdated)));
    } catch (e) {
      debugPrint('Updating balance failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      // Keep the form usable on small phones and with the keyboard open or
      // a large system text scale.
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      scrollable: true,
      title: Text(l10n.editBalance),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [AmountInputFormatter()],
        decoration: InputDecoration(hintText: l10n.newBalance),
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
