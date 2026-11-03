import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/data/models/budget.dart';
import 'package:gexpenses/data/models/expense.dart';
import 'package:gexpenses/data/models/income.dart';
import 'package:gexpenses/data/repositories/expense_repository.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';
import 'package:gexpenses/domain/services/backup_service.dart';
import 'package:gexpenses/domain/services/budget_service.dart';
import 'package:gexpenses/domain/services/expense_service.dart';
import 'package:gexpenses/domain/services/report_service.dart';
import 'package:gexpenses/presentation/providers/balance_providers.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(databaseHelperProvider));
});

final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService(
    ref.watch(expenseRepositoryProvider),
    ref.watch(databaseHelperProvider),
  );
});

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(
    ref.watch(expenseRepositoryProvider),
    ref.watch(balanceRepositoryProvider),
  );
});

final budgetServiceProvider = Provider<BudgetService>((ref) {
  return BudgetService(
    ref.watch(databaseHelperProvider),
    ref.watch(expenseRepositoryProvider),
  );
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(expenseRepositoryProvider));
});

/// Most recent expenses shown on the home screen.
final recentExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  return ref.watch(expenseServiceProvider).getRecentExpenses();
});

final incomesProvider = FutureProvider<List<Income>>((ref) async {
  return ref.watch(expenseServiceProvider).getIncomes();
});

/// Budgets for the current month, ordered by how close they are to the limit.
final budgetProgressProvider = FutureProvider<List<BudgetProgress>>((
  ref,
) async {
  return ref.watch(budgetServiceProvider).getProgress(DateTime.now());
});

/// Income, spending and net cash flow for the current calendar month.
class MonthSummary {
  final double income;
  final double spent;

  const MonthSummary({required this.income, required this.spent});

  double get net => income - spent;
}

final monthSummaryProvider = FutureProvider<MonthSummary>((ref) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month);
  final end = DateTime(now.year, now.month + 1);
  final income = await ref
      .watch(balanceRepositoryProvider)
      .getIncomeTotal(start, end);
  final spent = await ref
      .watch(expenseRepositoryProvider)
      .getTotalByDateRange(start, end);
  return MonthSummary(income: income, spent: spent);
});

/// Filter + page size for the "All expenses" screen.
class ExpenseFilter {
  final String query;
  final ExpenseCategory? category;
  final int limit;

  const ExpenseFilter({this.query = '', this.category, this.limit = 50});

  ExpenseFilter copyWith({
    String? query,
    ExpenseCategory? Function()? category,
    int? limit,
  }) {
    return ExpenseFilter(
      query: query ?? this.query,
      category: category != null ? category() : this.category,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExpenseFilter &&
      other.query == query &&
      other.category == category &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(query, category, limit);
}

final filteredExpensesProvider =
    FutureProvider.family<List<Expense>, ExpenseFilter>((ref, filter) {
      return ref
          .watch(expenseRepositoryProvider)
          .searchExpenses(
            query: filter.query,
            category: filter.category,
            limit: filter.limit,
          );
    });

/// Bumped whenever a report-affecting mutation happens, so report tabs
/// re-run their FutureBuilders and never show stale data.
final reportsVersionProvider = StateProvider<int>((ref) => 0);

/// Refreshes every provider affected by an expense/income/balance mutation.
void invalidateExpenseProviders(WidgetRef ref) {
  ref.invalidate(recentExpensesProvider);
  ref.invalidate(currentBalanceProvider);
  ref.invalidate(initialBalanceProvider);
  ref.invalidate(isLowBalanceProvider);
  ref.invalidate(hasBalanceProvider);
  ref.invalidate(incomesProvider);
  ref.invalidate(budgetProgressProvider);
  ref.invalidate(monthSummaryProvider);
  ref.invalidate(filteredExpensesProvider);
  ref.invalidate(reportsVersionProvider);
}
