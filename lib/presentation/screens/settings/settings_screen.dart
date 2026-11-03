import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/branding/brand_mark.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/amount_input.dart';
import 'package:gexpenses/core/utils/app_layout.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/balance_providers.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/screens/budgets/budgets_screen.dart';
import 'package:gexpenses/presentation/screens/expenses/all_expenses_screen.dart';
import 'package:gexpenses/presentation/screens/income/income_screen.dart';
import 'package:gexpenses/presentation/widgets/animated_amount.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
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
              final messenger = ScaffoldMessenger.of(context);
              if (amount == null || amount < 0) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.invalidAmount)),
                );
                return;
              }
              try {
                // Only adjust the CURRENT balance so the recorded expense
                // history stays intact.
                await ref
                    .read(balanceRepositoryProvider)
                    .updateCurrentBalance(amount);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                invalidateExpenseProviders(ref);
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.balanceUpdated)),
                );
              } catch (e) {
                debugPrint('Updating balance failed: $e');
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.errorGeneric)),
                );
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

  /// Shares a CSV or JSON backup through the platform share sheet (which also
  /// offers "Save to files" / download on desktop and web).
  Future<void> _exportData(
    BuildContext context,
    WidgetRef ref, {
    required bool asCsv,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final backup = ref.read(backupServiceProvider);
      final content = asCsv
          ? await backup.exportCsv()
          : await backup.exportJson();
      final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
      final fileName = 'gexpenses-$stamp.${asCsv ? 'csv' : 'json'}';

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(content),
              mimeType: asCsv ? 'text/csv' : 'application/json',
              name: fileName,
            ),
          ],
          fileNameOverrides: [fileName],
          subject: 'GExpenses backup ($stamp)',
        ),
      );
    } catch (e) {
      debugPrint('Export failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final picked = await FilePicker.pickFiles(
        dialogTitle: l10n.importBackup,
        type: FileType.custom,
        allowedExtensions: const ['csv', 'json'],
      );
      if (picked.isEmpty) return;

      final file = picked.single;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.importFailed)));
        return;
      }

      final content = utf8.decode(bytes, allowMalformed: true);
      final backup = ref.read(backupServiceProvider);
      final isJson = (file.extension ?? file.name).toLowerCase().endsWith(
        'json',
      );
      final result = isJson
          ? await backup.importJson(content)
          : await backup.importCsv(content);

      invalidateExpenseProviders(ref);
      if (result.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.importEmpty)));
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            [
              l10n.importDone(result.imported),
              if (result.skipped > 0) l10n.importSkipped(result.skipped),
            ].join(' · '),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Import failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.importFailed)));
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        scrollable: true,
        title: Text(l10n.resetDataTitle),
        content: Text(l10n.resetDataBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.resetDataConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(balanceRepositoryProvider).resetAllData();
      invalidateExpenseProviders(ref);
      messenger.showSnackBar(SnackBar(content: Text(l10n.dataReset)));
    } catch (e) {
      debugPrint('Reset failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
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

  void _open(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => screen));
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
                          onPressed: () => showIncomeEditor(context, ref),
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
              delay: const Duration(milliseconds: 100),
              child: _SettingsSection(
                title: l10n.reports,
                children: [
                  ListTile(
                    leading: const _IconBadge(icon: Icons.receipt_long_rounded),
                    title: Text(l10n.allExpenses),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _open(context, const AllExpensesScreen()),
                  ),
                  ListTile(
                    leading: const _IconBadge(icon: Icons.savings_rounded),
                    title: Text(l10n.incomeHistory),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _open(context, const IncomeScreen()),
                  ),
                  ListTile(
                    leading: const _IconBadge(
                      icon: Icons.pie_chart_outline_rounded,
                    ),
                    title: Text(l10n.budgets),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _open(context, const BudgetsScreen()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacing20),

            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
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
              delay: const Duration(milliseconds: 180),
              child: _SettingsSection(
                title: l10n.dataAndBackup,
                children: [
                  ListTile(
                    leading: const _IconBadge(icon: Icons.table_view_rounded),
                    title: Text(l10n.exportCsv),
                    subtitle: Text(l10n.exportReady),
                    onTap: () => _exportData(context, ref, asCsv: true),
                  ),
                  ListTile(
                    leading: const _IconBadge(icon: Icons.data_object_rounded),
                    title: Text(l10n.exportJson),
                    onTap: () => _exportData(context, ref, asCsv: false),
                  ),
                  ListTile(
                    leading: const _IconBadge(
                      icon: Icons.file_download_outlined,
                    ),
                    title: Text(l10n.importBackup),
                    subtitle: Text(l10n.importBalanceNote),
                    onTap: () => _importData(context, ref),
                  ),
                  ListTile(
                    leading: const _IconBadge(
                      icon: Icons.delete_forever_outlined,
                    ),
                    title: Text(
                      l10n.resetData,
                      style: TextStyle(color: colorScheme.error),
                    ),
                    onTap: () => _confirmReset(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacing20),

            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: _SettingsSection(
                title: l10n.about,
                children: [
                  ListTile(
                    leading: const BrandMark(size: 38),
                    title: Text(l10n.appName),
                    subtitle: Text(
                      '${l10n.version} ${AppConstants.appVersion}',
                    ),
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
