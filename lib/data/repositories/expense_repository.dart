import 'package:gexpenses/data/database/database_helper.dart';
import 'package:gexpenses/data/models/expense.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';

class ExpenseRepository {
  final DatabaseHelper _db;

  ExpenseRepository(this._db);

  Future<int> addExpense(Expense expense) async {
    final db = await _db.database;
    return db.insert('expenses', expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await _db.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await _db.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

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
          ExpenseCategory.values.firstWhere(
            (e) => e.name == r['category'],
            orElse: () => ExpenseCategory.other,
          ),
          (r['total'] as num).toDouble(),
        ),
      ),
    );
  }

  Future<Map<int, double>> getDailyTotals(
    DateTime start,
    DateTime end,
  ) async {
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
}
