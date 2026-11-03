import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/data/models/expense.dart';
import 'package:gexpenses/data/repositories/expense_repository.dart';
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
  return ReportService(ref.watch(expenseRepositoryProvider));
});

/// Most recent expenses shown on the home screen.
final recentExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  return ref.watch(expenseServiceProvider).getRecentExpenses();
});

/// Bumped whenever a report-affecting mutation happens, so report tabs
/// re-run their FutureBuilders and never show stale data.
final reportsVersionProvider = StateProvider<int>((ref) => 0);

/// Refreshes every provider affected by an expense/balance mutation.
void invalidateExpenseProviders(WidgetRef ref) {
  ref.invalidate(recentExpensesProvider);
  ref.invalidate(currentBalanceProvider);
  ref.invalidate(initialBalanceProvider);
  ref.invalidate(isLowBalanceProvider);
  ref.invalidate(hasBalanceProvider);
  ref.invalidate(reportsVersionProvider);
}
