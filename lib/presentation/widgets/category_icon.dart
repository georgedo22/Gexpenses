import 'package:flutter/material.dart';
import 'package:gexpenses/core/theme/app_colors.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';

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
    final color = AppColors.categoryColor(category);
    final iconSize = size * 0.5;

    return Container(
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
    );
  }
}
