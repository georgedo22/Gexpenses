import 'package:gexpenses/data/database/database_helper.dart';
import 'package:gexpenses/data/models/expense.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';

/// Read-only access to expenses.
///
/// Writes intentionally live in `ExpenseService`: every mutation has to adjust
/// the balance inside the same transaction, and exposing raw insert/update/
/// delete here used to make that easy to bypass.
class ExpenseRepository {
  final DatabaseHelper _db;

  ExpenseRepository(this._db);

  Future<Expense?> getExpense(int id) async {
    final result = await _db.getExpense(id);
    return result != null ? Expense.fromMap(result) : null;
  }

  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final results = await _db.getExpensesByDateRange(
      start.toIso8601String(),
      end.toIso8601String(),
    );
    return results.map((m) => Expense.fromMap(m)).toList();
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    return _db.getTotalByDateRange(
      start.toIso8601String(),
      end.toIso8601String(),
    );
  }

  Future<Map<ExpenseCategory, double>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async {
    final results = await _db.getCategoryTotalsByDateRange(
      start.toIso8601String(),
      end.toIso8601String(),
    );
    return Map.fromEntries(
      results.map(
        (r) => MapEntry(
          ExpenseCategory.fromName(r['category'] as String?),
          (r['total'] as num).toDouble(),
        ),
      ),
    );
  }

  Future<Map<int, double>> getDailyTotals(DateTime start, DateTime end) async {
    final results = await _db.getDailyTotalsByDateRange(
      start.toIso8601String(),
      end.toIso8601String(),
    );
    return Map.fromEntries(
      results.map((r) {
        final day = DateTime.parse(r['day'] as String);
        return MapEntry(day.day, (r['total'] as num).toDouble());
      }),
    );
  }

  Future<Map<int, double>> getMonthlyTotals(int year) async {
    final results = await _db.getMonthlyTotalsByYear(year);
    return Map.fromEntries(
      results.map(
        (r) => MapEntry(
          int.parse(r['month'] as String),
          (r['total'] as num).toDouble(),
        ),
      ),
    );
  }

  Future<List<Expense>> getRecentExpenses({int limit = 20}) async {
    final results = await _db.getRecentExpenses(limit);
    return results.map((m) => Expense.fromMap(m)).toList();
  }

  Future<List<Expense>> searchExpenses({
    String? query,
    ExpenseCategory? category,
    DateTime? start,
    DateTime? end,
    int limit = 50,
    int offset = 0,
  }) async {
    final results = await _db.searchExpenses(
      query: query,
      category: category?.name,
      startIso: start?.toIso8601String(),
      endIso: end?.toIso8601String(),
      limit: limit,
      offset: offset,
    );
    return results.map((m) => Expense.fromMap(m)).toList();
  }

  Future<List<Expense>> getAllExpenses() async {
    final results = await _db.getAllExpenses();
    return results.map((m) => Expense.fromMap(m)).toList();
  }

  /// Bulk import used by backup restore. It only inserts history: the current
  /// balance is deliberately left untouched so a restore can never silently
  /// overwrite the amount the user is tracking today.
  Future<int> importExpenses(List<Expense> expenses) {
    return _db.importExpenses(expenses.map((e) => e.toMap()).toList());
  }
}
