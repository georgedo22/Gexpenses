import 'package:flutter/material.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';
import 'package:gexpenses/l10n/app_localizations.dart';

/// Circular tinted icon for an expense category.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 44,
  });

  final ExpenseCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = category.colorFor(Theme.of(context).brightness);
    final iconSize = size * 0.5;

    return Semantics(
      label: AppLocalizations.of(context).categoryName(category),
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            category.icon,
            color: color,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
