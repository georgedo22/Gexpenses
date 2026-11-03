import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/app_layout.dart';
import 'package:gexpenses/core/utils/amount_input.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/data/models/expense.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';

/// Screen for adding a new expense or editing an existing one.
///
/// Pass an [expense] to edit it; otherwise the screen creates a new one.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.expense});

  final Expense? expense;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late ExpenseCategory _category;
  late DateTime _selectedDate;
  bool _isSaving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(
      text: expense != null ? expense.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: expense?.note ?? '');
    _category = expense?.category ?? ExpenseCategory.food;
    _selectedDate = expense?.dateTime ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;

    // Also let the user pick a time so back-dated expenses keep their exact
    // time of day.
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (!mounted) return;
    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time?.hour ?? _selectedDate.hour,
        time?.minute ?? _selectedDate.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final l10n = AppLocalizations.of(context);
      final service = ref.read(expenseServiceProvider);
      // Use the shared parser instead of double.parse: it accepts the
      // Arabic/Persian digits and decimal separators the formatter allows.
      final amount = parseAmountInput(_amountController.text);
      if (amount == null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
        return;
      }
      final title = _titleController.text.trim();
      final note = _noteController.text.trim();

      if (_isEditing) {
        final updated = widget.expense!.copyWith(
          amount: amount,
          title: title,
          category: _category,
          dateTime: _selectedDate,
          note: () => note.isEmpty ? null : note,
        );
        await service.updateExpense(widget.expense!, updated);
      } else {
        await service.addExpense(
          Expense(
            amount: amount,
            title: title,
            category: _category,
            dateTime: _selectedDate,
            note: note.isEmpty ? null : note,
          ),
        );
      }

      invalidateExpenseProviders(ref);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? l10n.expenseUpdated : l10n.expenseSaved),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Saving expense failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorGeneric)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Deletes the expense and returns its amount to the remaining balance.
  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.deleteExpense),
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
    if (confirmed != true) return;

    try {
      await ref.read(expenseServiceProvider).deleteExpense(widget.expense!);
      invalidateExpenseProviders(ref);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.expenseDeleted)));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editExpense : l10n.addExpense),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: colorScheme.error,
              tooltip: l10n.delete,
              onPressed: _isSaving ? null : _delete,
            ),
          const SizedBox(width: AppConstants.spacing8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveContent(
          maxWidth: AppLayout.formMaxWidth,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: AppLayout.pagePadding(
                    context,
                  ).add(const EdgeInsetsDirectional.only(top: 8, bottom: 16)),
                  children: [
                    FadeSlideIn(
                      child: TextFormField(
                        controller: _amountController,
                        autofocus: !_isEditing,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [AmountInputFormatter()],
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.amount,
                          prefixIcon: const Icon(Icons.payments_outlined),
                          prefixText: '${CurrencyFormatter.symbol} ',
                          prefixStyle: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.amountRequired;
                          }
                          final amount = parseAmountInput(value);
                          if (amount == null || amount <= 0) {
                            return l10n.invalidAmount;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 50),
                      child: TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.title,
                          prefixIcon: const Icon(Icons.edit_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.titleRequired;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(l10n.category),
                          const SizedBox(height: AppConstants.spacing12),
                          _CategoryPicker(
                            selected: _category,
                            onSelected: (category) =>
                                setState(() => _category = category),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Pressable(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          onTap: _pickDate,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppConstants.spacing16,
                              vertical: AppConstants.spacing12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: AppConstants.spacing12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.date,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.formatDateTime(_selectedDate),
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: l10n.note,
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _SaveBar(
                isSaving: _isSaving,
                isEditing: _isEditing,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

/// Category choices laid out in a responsive grid of tactile tiles.
class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected, required this.onSelected});

  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 440 ? 4 : 3;
        const spacing = AppConstants.spacing8;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final category in ExpenseCategory.values)
              SizedBox(
                width: itemWidth,
                child: _CategoryTile(
                  category: category,
                  label: l10n.categoryName(category),
                  selected: category == selected,
                  onTap: () => onSelected(category),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ExpenseCategory category;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = category.colorFor(Theme.of(context).brightness);
    final radius = BorderRadius.circular(AppConstants.borderRadius);

    return Pressable(
      borderRadius: radius,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.resolve(context, AppMotion.medium),
        curve: AppMotion.emphasized,
        height: 86,
        padding: const EdgeInsetsDirectional.all(AppConstants.spacing8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.14)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: radius,
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.7)
                : colorScheme.outlineVariant.withValues(alpha: 0.7),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1,
              duration: AppMotion.resolve(context, AppMotion.fast),
              curve: Curves.easeOut,
              child: Icon(category.icon, color: color, size: 22),
            ),
            const SizedBox(height: AppConstants.spacing8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Persistent action bar so saving never requires scrolling.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isSaving,
    required this.isEditing,
    required this.onPressed,
  });

  final bool isSaving;
  final bool isEditing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppConstants.spacing16,
            vertical: AppConstants.spacing12,
          ),
          child: SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: onPressed,
              child: AnimatedSwitcher(
                duration: AppMotion.resolve(context, AppMotion.fast),
                child: isSaving
                    ? SizedBox(
                        key: const ValueKey('saving'),
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Row(
                        key: ValueKey(isEditing),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEditing ? Icons.check_rounded : Icons.add_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: AppConstants.spacing8),
                          Text(
                            isEditing ? l10n.update : l10n.save,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
