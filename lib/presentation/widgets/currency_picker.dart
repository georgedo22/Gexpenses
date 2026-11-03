import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/constants/currencies.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bottom sheet listing every supported currency.
///
/// Shared by Settings and onboarding. Selecting a currency persists it,
/// updates [CurrencyFormatter.symbol] and refreshes every provider so all
/// formatted amounts update at once.
Future<void> showCurrencyPicker(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppConstants.spacing24,
              end: AppConstants.spacing24,
              bottom: AppConstants.spacing8,
            ),
            child: Text(
              l10n.chooseCurrency,
              style: Theme.of(
                sheetContext,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsetsDirectional.only(
                bottom: AppConstants.spacing16,
              ),
              children: [
                for (final option in kCurrencies)
                  ListTile(
                    leading: Text(
                      option.symbol,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    title: Text(l10n.currencyName(option.symbol)),
                    trailing: AnimatedSwitcher(
                      duration: AppMotion.medium,
                      child: CurrencyFormatter.symbol == option.symbol
                          ? Icon(
                              Icons.check_circle_rounded,
                              key: ValueKey(option.symbol),
                              color: Theme.of(
                                sheetContext,
                              ).colorScheme.primary,
                            )
                          : const SizedBox(width: 24, height: 24),
                    ),
                    onTap: () async {
                      CurrencyFormatter.symbol = option.symbol;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('currency_symbol', option.symbol);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                      invalidateExpenseProviders(ref);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.currencyUpdated)),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
