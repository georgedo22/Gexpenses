import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/app_layout.dart';
import 'package:gexpenses/core/utils/amount_input.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/balance_providers.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/widgets/animated_amount.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showEditBalanceDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // Keep the form usable on small phones and with the keyboard open or
        // a large system text scale.
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        scrollable: true,
        title: Text(l10n.editBalance),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [AmountInputFormatter()],
          decoration: InputDecoration(hintText: l10n.newBalance),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final amount = parseAmountInput(controller.text);
              if (amount == null || amount < 0) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
                return;
              }
              final repo = ref.read(balanceRepositoryProvider);
              // Only adjust the CURRENT balance so the recorded expense
              // history stays intact.
              await repo.updateCurrentBalance(amount);
              // invalidateExpenseProviders below also refreshes
              // currentBalanceProvider, initialBalanceProvider and
              // hasBalanceProvider, so the card updates on every platform.
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              invalidateExpenseProviders(ref);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.balanceUpdated)));
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    // NOTE: the controller is intentionally not disposed here. showDialog's
    // future completes as soon as the route is popped, while the dialog is
    // still mounted for its exit animation; disposing now makes the still
    // mounted TextField throw "A TextEditingController was used after being
    // disposed" during that animation.
  }

  Future<void> _showAddIncomeDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        scrollable: true,
        title: Text(l10n.addIncome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
              await service.addIncome(
                amount,
                description.isEmpty ? l10n.addIncome : description,
              );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              invalidateExpenseProviders(ref);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.incomeAdded)));
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    // Not disposed: see the note in _showEditBalanceDialog.
  }

  /// Shows a bottom sheet to pick the display currency, persists it and
  /// refreshes every provider so all formatted amounts update at once.
  Future<void> _showCurrencyPicker(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    const currencies = <String, String>{
      // Major currencies
      r'$': 'US Dollar (USD)',
      '₦': 'Nigerian Naira',
      'SYP': 'Syrian Pound',
      '€': 'Euro (EUR)',
      '£': 'British Pound (GBP)',
      '₹': 'Indian Rupee (INR)',
      '₨': 'Pakistani Rupee (PKR)',
      '৳': 'Bangladeshi Taka (BDT)',
      'د.إ': 'UAE Dirham (AED)',
      '﷼': 'Saudi Riyal (SAR)',
      '¥': 'Japanese Yen (JPY)',
      '₩': 'Korean Won (KRW)',
    };

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
                  for (final entry in currencies.entries)
                    ListTile(
                      leading: Text(
                        entry.key,
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                      title: Text(entry.value),
                      trailing: AnimatedSwitcher(
                        duration: AppMotion.medium,
                        child: CurrencyFormatter.symbol == entry.key
                            ? Icon(
                                Icons.check_circle_rounded,
                                key: ValueKey(entry.key),
                                color: Theme.of(
                                  sheetContext,
                                ).colorScheme.primary,
                              )
                            : const SizedBox(width: 24, height: 24),
                      ),
                      onTap: () async {
                        CurrencyFormatter.symbol = entry.key;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('currency_symbol', entry.key);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final currentBalanceAsync = ref.watch(currentBalanceProvider);

    return SafeArea(
      child: ResponsiveContent(
        child: ListView(
          padding: AppLayout.pagePadding(
            context,
          ).add(const EdgeInsetsDirectional.only(top: 12, bottom: 32)),
          children: [
            FadeSlideIn(
              child: Text(
                l10n.settings,
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacing20),

            // Balance overview
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: Container(
                padding: const EdgeInsetsDirectional.all(
                  AppConstants.spacing20,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusLarge,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.14),
                      colorScheme.tertiary.withValues(alpha: 0.06),
                    ],
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                  ),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currentBalance,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing8),
                    currentBalanceAsync.when(
                      data: (balance) => AnimatedAmount(
                        value: balance,
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      loading: () => const SizedBox(
                        height: 32,
                        width: 140,
                        child: LinearProgressIndicator(),
                      ),
                      error: (_, _) =>
                          Text('---', style: textTheme.headlineLarge),
                    ),
                    const SizedBox(height: AppConstants.spacing16),
                    // Wrapping (instead of a fixed Row) keeps both labels on
                    // one line when they fit and moves the second action to
                    // its own line otherwise, so nothing overflows at small
                    // widths or with a large system text scale.
                    Wrap(
                      spacing: AppConstants.spacing8,
                      runSpacing: AppConstants.spacing8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => _showEditBalanceDialog(context, ref),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(l10n.editBalance),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _showAddIncomeDialog(context, ref),
                          icon: const Icon(Icons.savings_outlined, size: 18),
                          label: Text(l10n.addIncome),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacing24),

            FadeSlideIn(
              delay: const Duration(milliseconds: 110),
              child: _SettingsSection(
                title: l10n.preferences,
                children: [
                  ListTile(
                    leading: const _IconBadge(
                      icon: Icons.currency_exchange_rounded,
                    ),
                    title: Text(l10n.currency),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyFormatter.symbol,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(width: AppConstants.spacing4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onTap: () => _showCurrencyPicker(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacing20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: _SettingsSection(
                title: l10n.about,
                children: [
                  ListTile(
                    leading: const _IconBadge(icon: Icons.info_outline_rounded),
                    title: Text(l10n.appName),
                    subtitle: Text('${l10n.version} 1.0.0'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppConstants.spacing4,
            bottom: AppConstants.spacing8,
          ),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Icon(icon, size: 19, color: colorScheme.primary),
    );
  }
}
