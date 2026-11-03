import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gexpenses/data/models/budget.dart';
import 'package:gexpenses/data/models/expense.dart';
import 'package:gexpenses/data/models/income.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/balance_providers.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/screens/add_expense/add_expense_screen.dart';
import 'package:gexpenses/presentation/screens/budgets/budgets_screen.dart';
import 'package:gexpenses/presentation/screens/expenses/all_expenses_screen.dart';
import 'package:gexpenses/presentation/screens/home/home_screen.dart';
import 'package:gexpenses/presentation/screens/income/income_screen.dart';
import 'package:gexpenses/presentation/screens/onboarding/set_balance_screen.dart';
import 'package:gexpenses/presentation/screens/settings/settings_screen.dart';

void main() {
  final now = DateTime.now();
  final seed = [
    Expense(
      id: 1,
      amount: 12.5,
      title: 'Morning coffee',
      category: ExpenseCategory.food,
      dateTime: now,
    ),
    Expense(
      id: 2,
      amount: 40,
      title: 'Weekly bus pass',
      category: ExpenseCategory.transport,
      dateTime: now.subtract(const Duration(days: 1)),
    ),
  ];

  /// Overrides every data provider a screen reads, so the widget tests stay
  /// fast and deterministic (no SQLite, no async isolate).
  List<Override> overrides() => [
    recentExpensesProvider.overrideWith((ref) async => seed),
    incomesProvider.overrideWith(
      (ref) async => [
        Income(
          id: 1,
          amount: 500,
          description: 'Salary',
          dateTime: now,
        ),
      ],
    ),
    currentBalanceProvider.overrideWith((ref) async => 447.5),
    initialBalanceProvider.overrideWith((ref) async => 500),
    isLowBalanceProvider.overrideWith((ref) async => false),
    hasBalanceProvider.overrideWith((ref) async => true),
    monthSummaryProvider.overrideWith(
      (ref) async => const MonthSummary(income: 500, spent: 52.5),
    ),
    budgetProgressProvider.overrideWith(
      (ref) async => [
        const BudgetProgress(
          category: ExpenseCategory.food,
          limit: 100,
          spent: 12.5,
        ),
        const BudgetProgress(
          category: ExpenseCategory.transport,
          limit: 20,
          spent: 40,
        ),
      ],
    ),
    filteredExpensesProvider.overrideWith((ref, filter) async {
      final query = filter.query.toLowerCase();
      return seed.where((expense) {
        final matchesQuery = query.isEmpty ||
            expense.title.toLowerCase().contains(query) ||
            (expense.note ?? '').toLowerCase().contains(query);
        final matchesCategory =
            filter.category == null || expense.category == filter.category;
        return matchesQuery && matchesCategory;
      }).toList();
    }),
  ];

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    List<Override>? extra,
  }) async {
    tester.view.physicalSize = const Size(430, 940);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...overrides(), ...?extra],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    // A few frames are enough: skeletons animate forever, so
    // `pumpAndSettle` would never return.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('home screen renders the recent expenses', (tester) async {
    await pumpScreen(
      tester,
      HomeScreen(onAddExpense: () {}, onViewAllExpenses: () {}),
    );

    expect(find.text('Current Balance'), findsOneWidget);
    expect(find.text('Morning coffee'), findsOneWidget);
    expect(find.text('Recent Expenses'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add expense screen renders its form', (tester) async {
    await pumpScreen(tester, const AddExpenseScreen());
    expect(find.text('Add Expense'), findsWidgets);
    expect(find.text('Amount'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all expenses screen lists, searches and shows empty state', (
    tester,
  ) async {
    await pumpScreen(tester, const AllExpensesScreen());

    expect(find.text('All expenses'), findsOneWidget);
    expect(find.text('Morning coffee'), findsOneWidget);

    Future<void> search(String text) async {
      await tester.enterText(find.byType(TextField).first, text);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    await search('bus');
    expect(find.text('Weekly bus pass'), findsOneWidget);
    expect(find.text('Morning coffee'), findsNothing);

    await search('zzzz');
    expect(find.text('Nothing matches this search'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('income screen shows entries and monthly summary', (
    tester,
  ) async {
    await pumpScreen(tester, const IncomeScreen());

    expect(find.text('Salary'), findsWidgets);
    expect(find.textContaining('+'), findsWidgets);
    expect(find.text('Income this month'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('budgets screen shows progress and warnings', (tester) async {
    await pumpScreen(tester, const BudgetsScreen());

    expect(find.text('Food & Dining'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Over budget'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings exposes the new sections', (tester) async {
    await pumpScreen(tester, const SettingsScreen());

    expect(find.text('All expenses'), findsOneWidget);
    expect(find.text('Income history'), findsOneWidget);
    expect(find.text('Monthly budgets'), findsOneWidget);
    expect(find.text('Export as CSV'), findsOneWidget);
    expect(find.text('Erase all data'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding screen asks for the starting balance', (
    tester,
  ) async {
    await pumpScreen(tester, const SetBalanceScreen());
    expect(find.text('Welcome to GExpenses'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('budget editor dialog opens and validates', (tester) async {
    await pumpScreen(tester, const BudgetsScreen());

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Set budget'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
