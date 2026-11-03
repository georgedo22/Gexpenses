import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() => _instance ??= DatabaseHelper._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Web (Edge/Chrome): use SQLite compiled to WASM instead of the
      // platform method channel, which does not exist on the web.
      databaseFactory = databaseFactoryFfiWeb;
    }
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'gexpenses.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        date_time TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        date_time TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE balance (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        initial_amount REAL NOT NULL,
        current_amount REAL NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_expenses_date_time ON expenses(date_time)',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_category ON expenses(category)',
    );
  }

  // === EXPENSE METHODS ===

  Future<int> insertExpense(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('expenses', data);
  }

  Future<int> updateExpense(Map<String, dynamic> data) async {
    final db = await database;
    return db.update(
      'expenses',
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getExpense(int id) async {
    final db = await database;
    final results = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getExpensesByDateRange(
    String startIso,
    String endIso,
  ) async {
    final db = await database;
    return db.query(
      'expenses',
      where: 'date_time >= ? AND date_time < ?',
      whereArgs: [startIso, endIso],
      orderBy: 'date_time DESC',
    );
  }

  Future<double> getTotalByDateRange(String startIso, String endIso) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses '
      'WHERE date_time >= ? AND date_time < ?',
      [startIso, endIso],
    );
    final total = result.first['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  Future<List<Map<String, dynamic>>> getCategoryTotalsByDateRange(
    String startIso,
    String endIso,
  ) async {
    final db = await database;
    return db.rawQuery(
      'SELECT category, SUM(amount) as total FROM expenses '
      'WHERE date_time >= ? AND date_time < ? '
      'GROUP BY category',
      [startIso, endIso],
    );
  }

  Future<List<Map<String, dynamic>>> getDailyTotalsByDateRange(
    String startIso,
    String endIso,
  ) async {
    final db = await database;
    return db.rawQuery(
      'SELECT date(date_time) as day, SUM(amount) as total FROM expenses '
      'WHERE date_time >= ? AND date_time < ? '
      'GROUP BY day ORDER BY day',
      [startIso, endIso],
    );
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotalsByYear(int year) async {
    final db = await database;
    return db.rawQuery(
      "SELECT strftime('%m', date_time) as month, SUM(amount) as total "
      'FROM expenses '
      "WHERE strftime('%Y', date_time) = ? "
      'GROUP BY month',
      [year.toString()],
    );
  }

  Future<List<Map<String, dynamic>>> getRecentExpenses(int limit) async {
    final db = await database;
    return db.query(
      'expenses',
      orderBy: 'date_time DESC',
      limit: limit,
    );
  }

  // === BALANCE METHODS ===

  Future<void> setBalance(double initialAmount, double currentAmount) async {
    final db = await database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO balance (id, initial_amount, current_amount) '
      'VALUES (1, ?, ?)',
      [initialAmount, currentAmount],
    );
  }

  Future<Map<String, dynamic>?> getBalance() async {
    final db = await database;
    final results = await db.query(
      'balance',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateCurrentBalance(double amount) async {
    final db = await database;
    final updated = await db.rawUpdate(
      'UPDATE balance SET current_amount = ? WHERE id = 1',
      [amount],
    );
    // A plain UPDATE silently affects zero rows when the balance row is
    // missing, which used to make "Save" look like it did nothing at all.
    if (updated == 0) {
      await db.rawInsert(
        'INSERT OR REPLACE INTO balance (id, initial_amount, current_amount) '
        'VALUES (1, ?, ?)',
        [amount, amount],
      );
    }
  }

  /// Atomically adjusts the current balance by [delta] (positive or negative)
  /// directly in SQL, avoiding the read-then-write race condition.
  Future<void> adjustBalance(double delta) async {
    final db = await database;
    final updated = await db.rawUpdate(
      'UPDATE balance SET current_amount = current_amount + ? WHERE id = 1',
      [delta],
    );
    if (updated == 0) {
      await db.rawInsert(
        'INSERT OR REPLACE INTO balance (id, initial_amount, current_amount) '
        'VALUES (1, 0, ?)',
        [delta],
      );
    }
  }

  /// Runs [action] inside a single SQLite transaction so that either all
  /// statements succeed or none of them are applied.
  Future<T> runInTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    return db.transaction(action);
  }

  // === TRANSACTION-SAFE HELPERS (must run inside runInTransaction) ===

  Future<void> insertExpenseInTx(Transaction txn, Map<String, dynamic> data) {
    return txn.insert('expenses', data);
  }

  Future<void> updateExpenseInTx(Transaction txn, Map<String, dynamic> data) {
    return txn.update(
      'expenses',
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  }

  Future<void> deleteExpenseInTx(Transaction txn, int id) {
    return txn.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertIncomeInTx(Transaction txn, Map<String, dynamic> data) {
    return txn.insert('incomes', data);
  }

  Future<void> adjustBalanceInTx(Transaction txn, double delta) async {
    final updated = await txn.rawUpdate(
      'UPDATE balance SET current_amount = current_amount + ? WHERE id = 1',
      [delta],
    );
    if (updated == 0) {
      await txn.rawInsert(
        'INSERT OR REPLACE INTO balance (id, initial_amount, current_amount) '
        'VALUES (1, 0, ?)',
        [delta],
      );
    }
  }

  // === INCOME METHODS ===

  Future<int> insertIncome(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('incomes', data);
  }

  Future<List<Map<String, dynamic>>> getIncomes() async {
    final db = await database;
    return db.query('incomes', orderBy: 'date_time DESC');
  }

  // For testing
  Future<void> close() async {
    _database?.close();
    _database = null;
  }
}
