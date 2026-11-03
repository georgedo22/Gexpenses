import 'package:gexpenses/domain/enums/expense_category.dart';

/// A monthly spending limit for one category.
class Budget {
  final ExpenseCategory category;
  final double limit;

  const Budget({required this.category, required this.limit});
}

/// A budget combined with what was actually spent in the current month.
class BudgetProgress {
  final ExpenseCategory category;
  final double limit;
  final double spent;

  const BudgetProgress({
    required this.category,
    required this.limit,
    required this.spent,
  });

  double get remaining => limit - spent;

  bool get isExceeded => spent > limit;

  /// 0..1 (clamped) so it can feed a progress indicator directly.
  double get ratio => limit <= 0 ? 0 : (spent / limit).clamp(0.0, 1.0);

  /// True once at least 80% of the budget is used.
  bool get isNearLimit => !isExceeded && ratio >= 0.8;
}
