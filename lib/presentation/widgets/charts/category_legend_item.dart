import 'package:flutter/material.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/widgets/category_icon.dart';

/// One row of the report category legend: icon, name, amount and a
/// percentage progress bar.
class CategoryLegendItem extends StatelessWidget {
  const CategoryLegendItem({
    super.key,
    required this.category,
    required this.amount,
    required this.total,
  });

  final ExpenseCategory category;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final percent = total > 0 ? (amount / total * 100) : 0.0;
    final color = category.colorFor(brightness);

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: AppConstants.spacing8,
      ),
      child: Row(
        children: [
          CategoryIcon(category: category, size: 36),
          const SizedBox(width: AppConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.categoryName(category),
                        style: textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing8),
                    Text(
                      CurrencyFormatter.format(amount),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing4),
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: (percent / 100).clamp(0.0, 1.0),
                        ),
                        duration: AppMotion.resolve(context, AppMotion.countUp),
                        curve: AppMotion.emphasized,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(3),
                          backgroundColor: color.withValues(alpha: 0.14),
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing8),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${percent.toStringAsFixed(0)}%',
                        textAlign: TextAlign.end,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
