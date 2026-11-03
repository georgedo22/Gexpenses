import 'package:gexpenses/data/database/database_helper.dart';
import 'package:gexpenses/data/models/budget.dart';
import 'package:gexpenses/data/repositories/expense_repository.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';

/// Stores monthly per-category limits and combines them with real spending.
class BudgetService {
  final DatabaseHelper _db;
  final ExpenseRepository _expenses;

  BudgetService(this._db, this._expenses);

  Future<Map<ExpenseCategory, double>> getBudgets() async {
    final rows = await _db.getBudgets();
    return {
      for (final row in rows)
        ExpenseCategory.fromName(row['category'] as String?):
            (row['amount'] as num).toDouble(),
    };
  }

  /// A limit of 0 (or less) removes the budget for [category].
  Future<void> setBudget(ExpenseCategory category, double limit) async {
    await _db.setBudget(category.name, limit);
  }

  /// Budgets with the amount spent in the month containing [month].
  Future<List<BudgetProgress>> getProgress(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    final budgets = await getBudgets();
    if (budgets.isEmpty) return const [];

    final spent = await _expenses.getCategoryTotals(start, end);

    final progress =
        budgets.entries
            .map(
              (entry) => BudgetProgress(
                category: entry.key,
                limit: entry.value,
                spent: spent[entry.key] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.ratio.compareTo(a.ratio));

    return progress;
  }
}
