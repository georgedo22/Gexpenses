import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gexpenses/data/database/database_helper.dart';
import 'package:gexpenses/data/models/expense.dart';
import 'package:gexpenses/data/models/income.dart';
import 'package:gexpenses/data/repositories/balance_repository.dart';
import 'package:gexpenses/data/repositories/expense_repository.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';
import 'package:gexpenses/domain/services/backup_service.dart';
import 'package:gexpenses/domain/services/budget_service.dart';
import 'package:gexpenses/domain/services/expense_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper db;
  late ExpenseService service;
  late ExpenseRepository expenses;
  late BalanceRepository balances;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    DatabaseHelper.overrideDatabasePath(inMemoryDatabasePath);
    db = DatabaseHelper();
    expenses = ExpenseRepository(db);
    balances = BalanceRepository(db);
    service = ExpenseService(expenses, db);
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.overrideDatabasePath(null);
  });

  Expense expense(
    double amount, {
    String title = 'Lunch',
    ExpenseCategory category = ExpenseCategory.food,
    DateTime? dateTime,
    String? note,
  }) => Expense(
    amount: amount,
    title: title,
    category: category,
    dateTime: dateTime ?? DateTime(2026, 3, 15, 12),
    note: note,
  );

  group('balance consistency', () {
    test('adding expenses keeps an exact balance (no float drift)', () async {
      await balances.setInitialBalance(1);
      for (var i = 0; i < 10; i++) {
        await service.addExpense(expense(0.1));
      }
      expect(await balances.getCurrentBalance(), 0.0);
      expect(await balances.getCurrentBalance(), isNot(0.000000001));
    });

    test('deleting an expense refunds the balance', () async {
      await balances.setInitialBalance(500);
      await service.addExpense(expense(125.75));
      expect(await balances.getCurrentBalance(), 374.25);

      final saved = (await expenses.getRecentExpenses()).single;
      await service.deleteExpense(saved);
      expect(await balances.getCurrentBalance(), 500);
    });

    test('editing an expense only applies the difference', () async {
      await balances.setInitialBalance(100);
      final original = expense(20);
      await service.addExpense(original);
      final saved = (await expenses.getRecentExpenses()).single;

      await service.updateExpense(saved, saved.copyWith(amount: 35.5));

      expect(await balances.getCurrentBalance(), 64.5);
      final reloaded = await expenses.getExpense(saved.id!);
      expect(reloaded!.amount, 35.5);
    });
  });

  group('expense persistence', () {
    test('clearing a note really clears it', () async {
      final saved = expense(10, note: 'with note');
      await service.addExpense(saved);
      final stored = (await expenses.getRecentExpenses()).single;
      expect(stored.note, 'with note');

      await service.updateExpense(stored, stored.copyWith(note: () => null));

      expect((await expenses.getExpense(stored.id!))!.note, isNull);
    });

    test('search matches title and note, and filters by category', () async {
      await service.addExpense(expense(4, title: 'Coffee', note: 'morning'));
      await service.addExpense(
        expense(9, title: 'Bus ticket', category: ExpenseCategory.transport),
      );
      await service.addExpense(
        expense(15, title: 'Groceries', note: 'coffee beans'),
      );

      final coffee = await expenses.searchExpenses(query: 'coffee');
      expect(coffee.length, 2);

      final transport = await expenses.searchExpenses(
        category: ExpenseCategory.transport,
      );
      expect(transport.single.title, 'Bus ticket');
    });

    test('paging returns stable pages ordered by date', () async {
      for (var i = 0; i < 6; i++) {
        await service.addExpense(
          expense(
            1 + i.toDouble(),
            title: 'Item $i',
            dateTime: DateTime(2026, 3, 1 + i),
          ),
        );
      }
      final firstPage = await expenses.searchExpenses(limit: 3, offset: 0);
      final secondPage = await expenses.searchExpenses(limit: 3, offset: 3);

      expect(firstPage.length, 3);
      expect(secondPage.length, 3);
      expect(
        firstPage.map((e) => e.title),
        isNot(secondPage.map((e) => e.title)),
      );
      expect(firstPage.first.title, 'Item 5');
    });
  });

  group('income', () {
    test('add, edit and delete keep the balance in sync', () async {
      await balances.setInitialBalance(100);

      await service.addIncome(50, 'Salary');
      expect(await balances.getCurrentBalance(), 150);

      final income = (await service.getIncomes()).single;
      await service.updateIncome(income, income.copyWith(amount: 80));
      expect(await balances.getCurrentBalance(), 180);

      await service.deleteIncome((await service.getIncomes()).single);
      expect(await balances.getCurrentBalance(), 100);
      expect(await service.getIncomes(), isEmpty);
    });

    test('monthly income total only counts the current month', () async {
      await service.addIncome(
        10,
        'Old',
        dateTime: DateTime(DateTime.now().year - 1, 1, 5),
      );
      await service.addIncome(25, 'Now');

      final now = DateTime.now();
      final total = await balances.getIncomeTotal(
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1),
      );
      expect(total, 25);
    });
  });

  group('budgets', () {
    test('progress reports spent, remaining and over-budget flags', () async {
      final budgets = BudgetService(db, expenses);
      await budgets.setBudget(ExpenseCategory.food, 100);
      await budgets.setBudget(ExpenseCategory.transport, 20);

      final now = DateTime.now();
      await service.addExpense(
        expense(120, category: ExpenseCategory.food, dateTime: now),
      );
      await service.addExpense(
        expense(5, category: ExpenseCategory.transport, dateTime: now),
      );

      final progress = await budgets.getProgress(now);
      final food = progress.firstWhere(
        (p) => p.category == ExpenseCategory.food,
      );
      final transport = progress.firstWhere(
        (p) => p.category == ExpenseCategory.transport,
      );

      expect(food.spent, 120);
      expect(food.isExceeded, isTrue);
      expect(food.remaining, -20);
      expect(food.ratio, 1.0);
      expect(transport.isNearLimit, isFalse);
      expect(transport.ratio, 0.25);
    });

    test('a zero limit removes the budget', () async {
      final budgets = BudgetService(db, expenses);
      await budgets.setBudget(ExpenseCategory.food, 50);
      expect(await budgets.getBudgets(), isNotEmpty);

      await budgets.setBudget(ExpenseCategory.food, 0);
      expect(await budgets.getBudgets(), isEmpty);
    });
  });

  group('backup', () {
    test('CSV round trip preserves amounts, categories and notes', () async {
      await service.addExpense(
        expense(12.34, title: 'Café, downtown', note: 'has "quotes"'),
      );
      await service.addExpense(
        expense(7, category: ExpenseCategory.health, title: 'Pharmacy'),
      );

      final backup = BackupService(expenses);
      final csv = await backup.exportCsv();
      expect(csv.split('\n').first.trim(), 'date,title,category,amount,note');

      // Import into a clean database.
      await db.resetAllData();
      expect(await expenses.getAllExpenses(), isEmpty);

      final result = await backup.importCsv(csv);
      expect(result.imported, 2);
      expect(result.skipped, 0);

      final restored = await expenses.getAllExpenses();
      expect(restored.length, 2);
      final cafe = restored.firstWhere((e) => e.title == 'Café, downtown');
      final pharmacy = restored.firstWhere((e) => e.title == 'Pharmacy');
      expect(cafe.note, 'has "quotes"');
      expect(cafe.amount, 12.34);
      expect(pharmacy.category, ExpenseCategory.health);
    });

    test('JSON round trip works and skips invalid rows', () async {
      await service.addExpense(expense(3.5, title: 'Water'));
      final backup = BackupService(expenses);
      final json = await backup.exportJson();

      await db.resetAllData();
      final result = await backup.importJson(json);
      expect(result.imported, 1);
      expect((await expenses.getAllExpenses()).single.amount, 3.5);

      final mixed = await backup.importJson(
        '[{"amount": 0, "title": "bad"}, {"amount": "x", "title": "worse"}]',
      );
      expect(mixed.imported, 0);
      expect(mixed.skipped, 2);
    });
  });

  group('reset', () {
    test('erases expenses, income, budgets and balance', () async {
      await balances.setInitialBalance(200);
      await service.addExpense(expense(10));
      await service.addIncome(5, 'Gift');
      await BudgetService(db, expenses).setBudget(ExpenseCategory.shopping, 40);

      await balances.resetAllData();

      expect(await expenses.getAllExpenses(), isEmpty);
      expect(await service.getIncomes(), isEmpty);
      expect(await BudgetService(db, expenses).getBudgets(), isEmpty);
      expect(await balances.hasBalance(), isFalse);
    });
  });

  group('migration from schema v1', () {
    test(
      'converts REAL amounts to integer cents without losing data',
      () async {
        final directory = Directory.systemTemp.createTempSync('gexpenses_test');
        final path = '${directory.path}/legacy.db';

        final legacy = await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (database, _) async {
              await database.execute('''
              CREATE TABLE expenses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                amount REAL NOT NULL,
                title TEXT NOT NULL,
                category TEXT NOT NULL,
                date_time TEXT NOT NULL,
                note TEXT
              )
            ''');
              await database.execute('''
              CREATE TABLE incomes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                amount REAL NOT NULL,
                description TEXT NOT NULL,
                date_time TEXT NOT NULL
              )
            ''');
              await database.execute('''
              CREATE TABLE balance (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                initial_amount REAL NOT NULL,
                current_amount REAL NOT NULL
              )
            ''');
            },
          ),
        );
        await legacy.insert('expenses', {
          'amount': 19.99,
          'title': 'Legacy expense',
          'category': 'food',
          'date_time': '2026-01-02T10:00:00.000',
        });
        await legacy.insert('incomes', {
          'amount': 100.5,
          'description': 'Legacy income',
          'date_time': '2026-01-03T10:00:00.000',
        });
        await legacy.insert('balance', {
          'id': 1,
          'initial_amount': 300.25,
          'current_amount': 280.26,
        });
        await legacy.close();

        DatabaseHelper.overrideDatabasePath(path);
        final migrated = DatabaseHelper();
        final repo = ExpenseRepository(migrated);
        final balanceRepo = BalanceRepository(migrated);

        final restored = (await repo.getAllExpenses()).single;
        expect(restored.amount, 19.99);
        expect(restored.title, 'Legacy expense');

        expect(await balanceRepo.getInitialBalance(), 300.25);
        expect(await balanceRepo.getCurrentBalance(), 280.26);

        final incomes = await migrated.getIncomes();
        expect(incomes.single['amount_cents'], 10050);

        // New writes work on the migrated schema.
        final service2 = ExpenseService(repo, migrated);
        await service2.addExpense(expense(0.01));
        expect(await balanceRepo.getCurrentBalance(), 280.25);

        await migrated.close();
        DatabaseHelper.overrideDatabasePath(null);
        directory.deleteSync(recursive: true);
      },
    );
  });

  group('model', () {
    test('unsaved expenses of different amounts are not equal', () {
      final a = expense(10);
      final b = expense(20);
      expect(a == b, isFalse);
      expect(expense(10) == expense(10), isTrue);
    });

    test('income survives a map round trip', () {
      final income = Income(
        id: 4,
        amount: 12.34,
        description: 'Refund',
        dateTime: DateTime(2026, 2, 1),
      );
      final restored = Income.fromMap(income.toMap());
      expect(restored.amount, 12.34);
      expect(restored.description, 'Refund');
      expect(restored.dateTime, income.dateTime);
    });
  });
}
