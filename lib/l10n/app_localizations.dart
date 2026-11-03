import 'package:flutter/material.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';

/// Lightweight hand-rolled localizations for the app (English only).
class AppLocalizations {
  const AppLocalizations();

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('en')];

  static AppLocalizations of(BuildContext context) {
    final instance = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(() {
      if (instance == null) {
        throw FlutterError(
          'No AppLocalizations found in context. Make sure '
          'AppLocalizations.delegate is registered on MaterialApp.',
        );
      }
      return true;
    }());
    return instance!;
  }

  // ── GENERAL ──────────────────────────────────────────────────────────
  String get appName => 'GExpenses';
  String get home => 'Home';
  String get reports => 'Reports';
  String get settings => 'Settings';
  String get viewAll => 'View all';
  String get preferences => 'Preferences';
  String get save => 'Save';
  String get update => 'Update';
  String get cancel => 'Cancel';
  String get delete => 'Delete';
  String get today => 'Today';
  String get yesterday => 'Yesterday';
  String get noData => 'No data for this period';

  // ── ONBOARDING ───────────────────────────────────────────────────────
  String get welcomeMessage => 'Welcome to GExpenses';
  String get welcomeSubtitle =>
      'Track your spending, stay on budget, and take control of your money.';
  String get enterInitialBalance => 'Enter your initial balance';
  String get enterAmount => '0.00';
  String get amountRequired => 'Please enter an amount';
  String get invalidAmount => 'Please enter a valid amount greater than 0';
  String get getStarted => 'Get Started';

  // ── BALANCE CARD ─────────────────────────────────────────────────────
  String get currentBalance => 'Current Balance';
  String get lowBalance => 'Low balance';
  String get initialBalance => 'Initial balance';

  // ── HOME ─────────────────────────────────────────────────────────────
  String get recentExpenses => 'Recent Expenses';
  String get noExpensesTitle => 'No expenses yet';
  String get noExpensesSubtitle =>
      'Tap the button below to add your first expense';

  // ── EXPENSE TILE / DIALOGS ───────────────────────────────────────────
  String get confirmDelete => 'Delete expense?';
  String get deleteExpense =>
      'This will remove the expense and return the amount to your balance.';
  String get expenseDeleted => 'Expense deleted · amount returned to balance';

  String categoryName(ExpenseCategory category) => category.label;

  // ── ADD / EDIT EXPENSE ───────────────────────────────────────────────
  String get addExpense => 'Add Expense';
  String get editExpense => 'Edit Expense';
  String get title => 'Title';
  String get titleRequired => 'Please enter a title';
  String get amount => 'Amount';
  String get category => 'Category';
  String get note => 'Note (optional)';
  String get date => 'Date';
  String get expenseSaved => 'Expense added';
  String get expenseUpdated => 'Expense updated';

  // ── REPORTS ──────────────────────────────────────────────────────────
  String get daily => 'Daily';
  String get weekly => 'Weekly';
  String get monthly => 'Monthly';
  String get yearly => 'Yearly';
  String get totalSpent => 'Total spent';
  String get dailyAverage => 'Daily average';
  String get monthlyAverage => 'Monthly average';
  String get vsPreviousPeriod => 'vs previous period';
  String get categoryBreakdown => 'Category Breakdown';
  String get monthlyBreakdown => 'Monthly Breakdown';
  String get topCategories => 'Top Categories';
  String get custom => 'Custom';
  String get customPeriod => 'Custom period';
  String get pickDateRange => 'Pick date range';
  String get from => 'From';
  String get to => 'To';
  String get perDay => 'Per day';
  String get expensesCount => 'Expenses';
  String get last7Days => 'Last 7 days';
  String get last30Days => 'Last 30 days';
  String get thisMonth => 'This month';
  String get lastMonth => 'Last month';

  // ── SETTINGS ─────────────────────────────────────────────────────────
  String get editBalance => 'Edit balance';
  String get newBalance => 'New balance';
  String get addIncome => 'Add income';
  String get incomeAmount => 'Income amount';
  String get description => 'Description';
  String get incomeAdded => 'Income added';
  String get balanceUpdated => 'Balance updated';
  String get about => 'About';
  String get version => 'Version';

  // ── CURRENCY / ERRORS ────────────────────────────────────────────────
  String get currency => 'Currency';
  String get chooseCurrency => 'Choose currency';
  String get currencyUpdated => 'Currency updated';
  String get skipForNow => 'Skip for now';
  String get errorTitle => 'Something went wrong';
  String get retry => 'Retry';
  String get errorGeneric => 'Something unexpected happened. Please try again.';

  // ── ALL EXPENSES ─────────────────────────────────────────────────────
  String get allExpenses => 'All expenses';
  String get searchExpenses => 'Search by title or note';
  String get noResults => 'Nothing matches this search';
  String get noResultsSubtitle => 'Try a different keyword or clear filters.';
  String get clearFilters => 'Clear filters';
  String get allCategories => 'All';
  String get loadMore => 'Load more';
  String get filters => 'Filters';
  String get expenseCount => 'expenses';

  // ── INCOME ──────────────────────────────────────────────────────────
  String get incomeHistory => 'Income history';
  String get noIncomes => 'No income recorded';
  String get noIncomesSubtitle =>
      'Add salary or other money you received to track your real cash flow.';
  String get editIncome => 'Edit income';
  String get deleteIncome => 'Delete income?';
  String get deleteIncomeBody =>
      'This removes the entry and subtracts the amount from your balance.';
  String get incomeDeleted => 'Income deleted';
  String get incomeUpdated => 'Income updated';
  String get incomeThisMonth => 'Income this month';
  String get netFlowThisMonth => 'Net this month';

  // ── BUDGETS ─────────────────────────────────────────────────────────
  String get budgets => 'Monthly budgets';
  String get budgetFor => 'Budget for';
  String get setBudget => 'Set budget';
  String get budgetUpdated => 'Budget updated';
  String get noBudgets => 'No budgets yet';
  String get noBudgetsSubtitle =>
      'Set a monthly limit per category and GExpenses will tell you when you '
      'are getting close.';
  String get overBudget => 'Over budget';
  String get nearLimit => 'Close to limit';
  String get spentLabel => 'spent';
  String get remainingLabel => 'remaining';
  String get removeBudget => 'Remove budget';
  String get budgetRemoveHint => 'Enter 0 to remove this budget';

  // ── DATA & BACKUP ─────────────────────────────────────────────────────
  String get dataAndBackup => 'Data & backup';
  String get exportCsv => 'Export as CSV';
  String get exportJson => 'Export as JSON';
  String get importBackup => 'Import from file';
  String get exportReady => 'Backup created';
  String get exportFailed => 'Could not create the backup';
  String importDone(int imported) => '$imported expenses imported';
  String importSkipped(int skipped) => '$skipped rows skipped';
  String get importEmpty => 'No valid expenses found in that file';
  String get importFailed => 'Could not read that file';
  String get importBalanceNote =>
      'Imported expenses are added to your history. Your current balance is '
      'not changed.';
  String get resetData => 'Erase all data';
  String get resetDataTitle => 'Erase everything?';
  String get resetDataBody =>
      'This permanently deletes every expense, income, budget and your '
      'balance. Export a backup first if you might need this data.';
  String get resetDataConfirm => 'Erase';
  String get dataReset => 'All data erased';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      const AppLocalizations();

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
