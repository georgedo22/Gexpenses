import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as p;

/// Central SQLite access layer.
///
/// Money is stored as **integer minor units** (cents) so repeated additions
/// can never drift the way floating point values do. Everything above this
/// class still works with `double` amounts; the conversion happens here and in
/// the model `toMap`/`fromMap` methods only.
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;
  static String? _pathOverride;

  /// Current schema version. Bump together with a new `_onUpgrade` step.
  static const int schemaVersion = 2;

  DatabaseHelper._();

  factory DatabaseHelper() => _instance ??= DatabaseHelper._();

  /// Lets tests open a temporary/in-memory database instead of the real one.
  @visibleForTesting
  static void overrideDatabasePath(String? path) {
    _pathOverride = path;
    _database = null;
  }

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
    final path = _pathOverride ?? p.join(dbPath, 'gexpenses.db');
    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount_cents INTEGER NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        date_time TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount_cents INTEGER NOT NULL,
        description TEXT NOT NULL,
        date_time TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE balance (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        initial_cents INTEGER NOT NULL,
        current_cents INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        category TEXT PRIMARY KEY,
        amount_cents INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await _createIndexes(db);
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_date_time ON expenses(date_time)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_incomes_date_time ON incomes(date_time)',
    );
  }

  /// Migrates an existing database without touching user data:
  /// v1 stored REAL amounts, v2 stores integer cents and adds `budgets`.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE expenses_v2 (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount_cents INTEGER NOT NULL,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          date_time TEXT NOT NULL,
          note TEXT
        )
      ''');
      await db.execute('''
        INSERT INTO expenses_v2 (id, amount_cents, title, category, date_time, note)
        SELECT id, CAST(ROUND(amount * 100) AS INTEGER), title, category,
               date_time, note
        FROM expenses
      ''');
      await db.execute('DROP TABLE expenses');
      await db.execute('ALTER TABLE expenses_v2 RENAME TO expenses');

      await db.execute('''
        CREATE TABLE incomes_v2 (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount_cents INTEGER NOT NULL,
          description TEXT NOT NULL,
          date_time TEXT NOT NULL
        )
      ''');
      await db.execute('''
        INSERT INTO incomes_v2 (id, amount_cents, description, date_time)
        SELECT id, CAST(ROUND(amount * 100) AS INTEGER), description, date_time
        FROM incomes
      ''');
      await db.execute('DROP TABLE incomes');
      await db.execute('ALTER TABLE incomes_v2 RENAME TO incomes');

      await db.execute('''
        CREATE TABLE balance_v2 (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          initial_cents INTEGER NOT NULL,
          current_cents INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        INSERT INTO balance_v2 (id, initial_cents, current_cents)
        SELECT id, CAST(ROUND(initial_amount * 100) AS INTEGER),
               CAST(ROUND(current_amount * 100) AS INTEGER)
        FROM balance
      ''');
      await db.execute('DROP TABLE balance');
      await db.execute('ALTER TABLE balance_v2 RENAME TO balance');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          category TEXT PRIMARY KEY,
          amount_cents INTEGER NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await _createIndexes(db);
    }
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

  /// Searchable, filterable, paged history used by the "All expenses" screen.
  Future<List<Map<String, dynamic>>> searchExpenses({
    String? query,
    String? category,
    String? startIso,
    String? endIso,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];

    final trimmed = query?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      where.add('(title LIKE ? OR IFNULL(note, \'\') LIKE ?)');
      args
        ..add('%$trimmed%')
        ..add('%$trimmed%');
    }
    if (category != null) {
      where.add('category = ?');
      args.add(category);
    }
    if (startIso != null) {
      where.add('date_time >= ?');
      args.add(startIso);
    }
    if (endIso != null) {
      where.add('date_time < ?');
      args.add(endIso);
    }

    return db.query(
      'expenses',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date_time DESC, id DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<double> getTotalByDateRange(String startIso, String endIso) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount_cents) as total FROM expenses '
      'WHERE date_time >= ? AND date_time < ?',
      [startIso, endIso],
    );
    return _centsToDouble(result.first['total']);
  }

  Future<List<Map<String, dynamic>>> getCategoryTotalsByDateRange(
    String startIso,
    String endIso,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT category, SUM(amount_cents) as total_cents FROM expenses '
      'WHERE date_time >= ? AND date_time < ? '
      'GROUP BY category',
      [startIso, endIso],
    );
    return rows
        .map(
          (r) => {
            'category': r['category'],
            'total': _centsToDouble(r['total_cents']),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getDailyTotalsByDateRange(
    String startIso,
    String endIso,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT date(date_time) as day, SUM(amount_cents) as total_cents '
      'FROM expenses '
      'WHERE date_time >= ? AND date_time < ? '
      'GROUP BY day ORDER BY day',
      [startIso, endIso],
    );
    return rows
        .map(
          (r) => {'day': r['day'], 'total': _centsToDouble(r['total_cents'])},
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotalsByYear(int year) async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT strftime('%m', date_time) as month, "
      'SUM(amount_cents) as total_cents '
      'FROM expenses '
      "WHERE strftime('%Y', date_time) = ? "
      'GROUP BY month',
      [year.toString()],
    );
    return rows
        .map(
          (r) => {
            'month': r['month'],
            'total': _centsToDouble(r['total_cents']),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getRecentExpenses(int limit) async {
    final db = await database;
    return db.query('expenses', orderBy: 'date_time DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final db = await database;
    return db.query('expenses', orderBy: 'date_time ASC');
  }

  // === BALANCE METHODS ===

  Future<void> setBalance(double initialAmount, double currentAmount) async {
    final db = await database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO balance (id, initial_cents, current_cents) '
      'VALUES (1, ?, ?)',
      [_toCents(initialAmount), _toCents(currentAmount)],
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
      'UPDATE balance SET current_cents = ? WHERE id = 1',
      [_toCents(amount)],
    );
    // A plain UPDATE silently affects zero rows when the balance row is
    // missing, which used to make "Save" look like it did nothing at all.
    if (updated == 0) {
      await db.rawInsert(
        'INSERT OR REPLACE INTO balance (id, initial_cents, current_cents) '
        'VALUES (1, ?, ?)',
        [_toCents(amount), _toCents(amount)],
      );
    }
  }

  /// Atomically adjusts the current balance by [delta] (positive or negative)
  /// directly in SQL, avoiding the read-then-write race condition.
  Future<void> adjustBalance(double delta) async {
    final db = await database;
    final updated = await db.rawUpdate(
      'UPDATE balance SET current_cents = current_cents + ? WHERE id = 1',
      [_toCents(delta)],
    );
    if (updated == 0) {
      await db.rawInsert(
        'INSERT OR REPLACE INTO balance (id, initial_cents, current_cents) '
        'VALUES (1, 0, ?)',
        [_toCents(delta)],
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

  Future<int> insertExpenseInTx(Transaction txn, Map<String, dynamic> data) {
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

  Future<int> insertIncomeInTx(Transaction txn, Map<String, dynamic> data) {
    return txn.insert('incomes', data);
  }

  Future<void> updateIncomeInTx(Transaction txn, Map<String, dynamic> data) {
    return txn.update(
      'incomes',
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  }

  Future<void> deleteIncomeInTx(Transaction txn, int id) {
    return txn.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> adjustBalanceInTx(Transaction txn, double delta) async {
    final updated = await txn.rawUpdate(
      'UPDATE balance SET current_cents = current_cents + ? WHERE id = 1',
      [_toCents(delta)],
    );
    if (updated == 0) {
      await txn.rawInsert(
        'INSERT OR REPLACE INTO balance (id, initial_cents, current_cents) '
        'VALUES (1, 0, ?)',
        [_toCents(delta)],
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
    return db.query('incomes', orderBy: 'date_time DESC, id DESC');
  }

  Future<double> getTotalIncomeByDateRange(
    String startIso,
    String endIso,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount_cents) as total FROM incomes '
      'WHERE date_time >= ? AND date_time < ?',
      [startIso, endIso],
    );
    return _centsToDouble(result.first['total']);
  }

  // === BUDGET METHODS ===

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final db = await database;
    final rows = await db.query('budgets');
    return rows
        .map(
          (r) => {
            'category': r['category'],
            'amount': _centsToDouble(r['amount_cents']),
          },
        )
        .toList();
  }

  Future<void> setBudget(String category, double amount) async {
    final db = await database;
    if (amount <= 0) {
      await db.delete('budgets', where: 'category = ?', whereArgs: [category]);
      return;
    }
    await db.rawInsert(
      'INSERT OR REPLACE INTO budgets (category, amount_cents, updated_at) '
      'VALUES (?, ?, ?)',
      [category, _toCents(amount), DateTime.now().toIso8601String()],
    );
  }

  /// Removes every expense, income, budget and resets the balance so the app
  /// starts from a clean state. Runs as one transaction.
  Future<void> resetAllData() async {
    await runInTransaction((txn) async {
      await txn.delete('expenses');
      await txn.delete('incomes');
      await txn.delete('budgets');
      await txn.delete('balance');
    });
  }

  /// Inserts many imported expenses in a single transaction.
  Future<int> importExpenses(List<Map<String, dynamic>> rows) async {
    return runInTransaction((txn) async {
      for (final row in rows) {
        await txn.insert('expenses', row);
      }
      return rows.length;
    });
  }

  // For testing
  Future<void> close() async {
    _database?.close();
    _database = null;
  }

  static int _toCents(double amount) => (amount * 100).round();

  static double _centsToDouble(Object? cents) =>
      cents == null ? 0.0 : (cents as num).toInt() / 100.0;
}
