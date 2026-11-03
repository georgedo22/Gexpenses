import 'package:gexpenses/data/database/database_helper.dart';
import 'package:gexpenses/data/models/income.dart';

class BalanceRepository {
  final DatabaseHelper _db;

  BalanceRepository(this._db);

  Future<bool> hasBalance() async {
    final result = await _db.getBalance();
    return result != null;
  }

  Future<void> setInitialBalance(double amount) async {
    await _db.setBalance(amount, amount);
  }

  Future<double> getInitialBalance() async {
    final result = await _db.getBalance();
    final cents = result?['initial_cents'] as num?;
    return cents == null ? 0.0 : cents.toInt() / 100.0;
  }

  Future<double> getCurrentBalance() async {
    final result = await _db.getBalance();
    final cents = result?['current_cents'] as num?;
    return cents == null ? 0.0 : cents.toInt() / 100.0;
  }

  Future<void> updateCurrentBalance(double newBalance) async {
    await _db.updateCurrentBalance(newBalance);
  }

  /// Atomically adjusts the balance directly in SQL (no read-then-write race).
  Future<void> addToBalance(double amount) => _db.adjustBalance(amount);

  Future<void> subtractFromBalance(double amount) => _db.adjustBalance(-amount);

  Future<List<Income>> getIncomes() async {
    final results = await _db.getIncomes();
    return results.map((m) => Income.fromMap(m)).toList();
  }

  Future<double> getIncomeTotal(DateTime start, DateTime end) {
    return _db.getTotalIncomeByDateRange(
      start.toIso8601String(),
      end.toIso8601String(),
    );
  }

  Future<void> resetAllData() => _db.resetAllData();
}
