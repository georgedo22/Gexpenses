import 'package:gexpenses/data/database/database_helper.dart';
import 'package:gexpenses/data/models/expense.dart';
import 'package:gexpenses/data/models/income.dart';
import 'package:gexpenses/data/repositories/expense_repository.dart';

class ExpenseService {
  final ExpenseRepository _expenseRepo;
  final DatabaseHelper _db;

  ExpenseService(this._expenseRepo, this._db);

  /// Inserts the expense and adjusts the balance in a single atomic
  /// transaction, so the two can never get out of sync.
  Future<void> addExpense(Expense expense) async {
    await _db.runInTransaction((txn) async {
      await _db.insertExpenseInTx(txn, expense.toMap());
      await _db.adjustBalanceInTx(txn, -expense.amount);
    });
  }

  /// Updates the expense and adjusts the balance by the amount difference
  /// in a single atomic transaction.
  Future<void> updateExpense(Expense oldExpense, Expense newExpense) async {
    await _db.runInTransaction((txn) async {
      await _db.updateExpenseInTx(txn, newExpense.toMap());
      final difference = newExpense.amount - oldExpense.amount;
      if (difference != 0) {
        await _db.adjustBalanceInTx(txn, -difference);
      }
    });
  }

  /// Deletes the expense and returns its amount to the balance in a single
  /// atomic transaction.
  Future<void> deleteExpense(Expense expense) async {
    await _db.runInTransaction((txn) async {
      await _db.deleteExpenseInTx(txn, expense.id!);
      await _db.adjustBalanceInTx(txn, expense.amount);
    });
  }

  /// Records the income and credits the balance in a single atomic
  /// transaction.
  Future<void> addIncome(double amount, String description) async {
    final income = Income(
      amount: amount,
      description: description,
      dateTime: DateTime.now(),
    );
    await _db.runInTransaction((txn) async {
      await _db.insertIncomeInTx(txn, income.toMap());
      await _db.adjustBalanceInTx(txn, amount);
    });
  }

  Future<List<Expense>> getRecentExpenses({int limit = 20}) async {
    return _expenseRepo.getRecentExpenses(limit: limit);
  }

  Future<Expense?> getExpense(int id) async {
    return _expenseRepo.getExpense(id);
  }
}
