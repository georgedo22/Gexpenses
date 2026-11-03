import 'package:flutter/material.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';
import 'package:intl/intl.dart';

/// Lightweight hand-rolled localizations for the app (English + Arabic).
///
/// [AppLocalizations] itself is the English implementation; [AppLocalizationsAr]
/// overrides every string (and date helper) for Arabic. Flutter handles RTL
/// automatically once `Locale('ar')` is resolved and the global localization
/// delegates from `flutter_localizations` are registered in `main.dart`
/// (they also initialize the `intl` date symbols for the locale).
class AppLocalizations {
  const AppLocalizations();

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('en'), Locale('ar')];

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
  String get previous => 'Previous';
  String get next => 'Next';

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
  String get categories => 'Categories';
  String get jumpToDate => 'Jump to date';
  String weekOf(String range) => 'Week of $range';

  // ── CHART SEMANTICS ──────────────────────────────────────────────────
  String get chartDailySpending => 'Bar chart of daily spending';
  String get chartWeeklySpending => 'Bar chart of spending for each weekday';
  String get chartMonthlySpending => 'Bar chart of monthly spending';
  String get chartCategoryBreakdown => 'Pie chart of spending by category';

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

  /// Display name for a currency [symbol] from `kCurrencies`.
  String currencyName(String symbol) {
    switch (symbol) {
      case r'$':
        return 'US Dollar (USD)';
      case '₦':
        return 'Nigerian Naira';
      case 'SYP':
        return 'Syrian Pound';
      case '€':
        return 'Euro (EUR)';
      case '£':
        return 'British Pound (GBP)';
      case '₹':
        return 'Indian Rupee (INR)';
      case '₨':
        return 'Pakistani Rupee (PKR)';
      case '৳':
        return 'Bangladeshi Taka (BDT)';
      case 'د.إ':
        return 'UAE Dirham (AED)';
      case '﷼':
        return 'Saudi Riyal (SAR)';
      case '¥':
        return 'Japanese Yen (JPY)';
      case '₩':
        return 'Korean Won (KRW)';
      default:
        return symbol;
    }
  }

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

  // ── DATES ────────────────────────────────────────────────────────────
  // Relative labels.
  String daysAgo(int days) => '$days days ago';

  String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return this.today;
    if (diff == 1) return yesterday;
    if (diff > 1 && diff < 7) return daysAgo(diff);
    return formatShortDate(date);
  }

  // Absolute formats. The base (English) implementation relies on the default
  // `intl` locale; the Arabic subclass pins the `ar` locale (its date symbols
  // are initialized by `GlobalMaterialLocalizations` in `main.dart`).
  String headerDate(DateTime date) =>
      DateFormat('EEEE, MMMM d').format(date);

  String formatDate(DateTime date) =>
      DateFormat('EEE, MMM d, yyyy').format(date);

  String formatShortDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  String formatMonthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  String formatDateTime(DateTime date) =>
      DateFormat('EEE, MMM d, yyyy · h:mm a').format(date);

  String weekdayShort(DateTime date) => DateFormat('E').format(date);

  /// Single-letter month marker used by the yearly bar chart.
  String monthInitial(int month) {
    const initials = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    return initials[(month - 1).clamp(0, 11)];
  }
}

/// Arabic localization.
class AppLocalizationsAr extends AppLocalizations {
  const AppLocalizationsAr();

  // ── GENERAL ──────────────────────────────────────────────────────────
  @override
  String get home => 'الرئيسية';
  @override
  String get reports => 'التقارير';
  @override
  String get settings => 'الإعدادات';
  @override
  String get viewAll => 'عرض الكل';
  @override
  String get preferences => 'التفضيلات';
  @override
  String get save => 'حفظ';
  @override
  String get update => 'تحديث';
  @override
  String get cancel => 'إلغاء';
  @override
  String get delete => 'حذف';
  @override
  String get today => 'اليوم';
  @override
  String get yesterday => 'أمس';
  @override
  String get noData => 'لا توجد بيانات لهذه الفترة';
  @override
  String get previous => 'السابق';
  @override
  String get next => 'التالي';

  // ── ONBOARDING ───────────────────────────────────────────────────────
  @override
  String get welcomeMessage => 'مرحبًا بك في GExpenses';
  @override
  String get welcomeSubtitle =>
      'تابع إنفاقك، والتزم بميزانيتك، وتولَّ أموالك.';
  @override
  String get enterInitialBalance => 'أدخل رصيدك الأولي';
  @override
  String get amountRequired => 'يرجى إدخال مبلغ';
  @override
  String get invalidAmount => 'يرجى إدخال مبلغ صالح أكبر من 0';
  @override
  String get getStarted => 'ابدأ الآن';

  // ── BALANCE CARD ─────────────────────────────────────────────────────
  @override
  String get currentBalance => 'الرصيد الحالي';
  @override
  String get lowBalance => 'رصيد منخفض';
  @override
  String get initialBalance => 'الرصيد الأولي';

  // ── HOME ─────────────────────────────────────────────────────────────
  @override
  String get recentExpenses => 'أحدث المصروفات';
  @override
  String get noExpensesTitle => 'لا توجد مصروفات بعد';
  @override
  String get noExpensesSubtitle => 'اضغط على الزر أدناه لإضافة أول مصروف';

  // ── EXPENSE TILE / DIALOGS ───────────────────────────────────────────
  @override
  String get confirmDelete => 'حذف المصروف؟';
  @override
  String get deleteExpense =>
      'سيؤدي هذا إلى إزالة المصروف وإعادة المبلغ إلى رصيدك.';
  @override
  String get expenseDeleted => 'تم حذف المصروف · أُعيد المبلغ إلى الرصيد';

  @override
  String categoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'الطعام والمطاعم';
      case ExpenseCategory.transport:
        return 'المواصلات';
      case ExpenseCategory.bills:
        return 'الفواتير والخدمات';
      case ExpenseCategory.shopping:
        return 'التسوق';
      case ExpenseCategory.health:
        return 'الصحة واللياقة';
      case ExpenseCategory.entertainment:
        return 'الترفيه';
      case ExpenseCategory.other:
        return 'أخرى';
    }
  }

  // ── ADD / EDIT EXPENSE ───────────────────────────────────────────────
  @override
  String get addExpense => 'إضافة مصروف';
  @override
  String get editExpense => 'تعديل المصروف';
  @override
  String get title => 'العنوان';
  @override
  String get titleRequired => 'يرجى إدخال عنوان';
  @override
  String get amount => 'المبلغ';
  @override
  String get category => 'الفئة';
  @override
  String get note => 'ملاحظة (اختياري)';
  @override
  String get date => 'التاريخ';
  @override
  String get expenseSaved => 'تمت إضافة المصروف';
  @override
  String get expenseUpdated => 'تم تحديث المصروف';

  // ── REPORTS ──────────────────────────────────────────────────────────
  @override
  String get daily => 'يومي';
  @override
  String get weekly => 'أسبوعي';
  @override
  String get monthly => 'شهري';
  @override
  String get yearly => 'سنوي';
  @override
  String get totalSpent => 'إجمالي المصروفات';
  @override
  String get dailyAverage => 'المتوسط اليومي';
  @override
  String get monthlyAverage => 'المتوسط الشهري';
  @override
  String get vsPreviousPeriod => 'مقارنة بالفترة السابقة';
  @override
  String get categoryBreakdown => 'التوزيع حسب الفئة';
  @override
  String get monthlyBreakdown => 'التوزيع الشهري';
  @override
  String get topCategories => 'أعلى الفئات';
  @override
  String get custom => 'مخصص';
  @override
  String get customPeriod => 'فترة مخصصة';
  @override
  String get pickDateRange => 'اختر نطاق التاريخ';
  @override
  String get from => 'من';
  @override
  String get to => 'إلى';
  @override
  String get perDay => 'لكل يوم';
  @override
  String get expensesCount => 'مصروفات';
  @override
  String get last7Days => 'آخر 7 أيام';
  @override
  String get last30Days => 'آخر 30 يومًا';
  @override
  String get thisMonth => 'هذا الشهر';
  @override
  String get lastMonth => 'الشهر الماضي';
  @override
  String get categories => 'الفئات';
  @override
  String get jumpToDate => 'الانتقال إلى تاريخ';
  @override
  String weekOf(String range) => 'أسبوع $range';

  // ── CHART SEMANTICS ──────────────────────────────────────────────────
  @override
  String get chartDailySpending => 'مخطط أعمدة للإنفاق اليومي';
  @override
  String get chartWeeklySpending => 'مخطط أعمدة للإنفاق لكل يوم من الأسبوع';
  @override
  String get chartMonthlySpending => 'مخطط أعمدة للإنفاق الشهري';
  @override
  String get chartCategoryBreakdown => 'مخطط دائري للإنفاق حسب الفئة';

  // ── SETTINGS ─────────────────────────────────────────────────────────
  @override
  String get editBalance => 'تعديل الرصيد';
  @override
  String get newBalance => 'الرصيد الجديد';
  @override
  String get addIncome => 'إضافة دخل';
  @override
  String get incomeAmount => 'مبلغ الدخل';
  @override
  String get description => 'الوصف';
  @override
  String get incomeAdded => 'تمت إضافة الدخل';
  @override
  String get balanceUpdated => 'تم تحديث الرصيد';
  @override
  String get about => 'حول التطبيق';
  @override
  String get version => 'الإصدار';

  // ── CURRENCY / ERRORS ────────────────────────────────────────────────
  @override
  String get currency => 'العملة';
  @override
  String get chooseCurrency => 'اختر العملة';
  @override
  String get currencyUpdated => 'تم تحديث العملة';
  @override
  String get skipForNow => 'تخطَّ الآن';
  @override
  String get errorTitle => 'حدث خطأ ما';
  @override
  String get retry => 'إعادة المحاولة';
  @override
  String get errorGeneric => 'حدث شيء غير متوقع. يرجى المحاولة مرة أخرى.';

  @override
  String currencyName(String symbol) {
    switch (symbol) {
      case r'$':
        return 'الدولار الأمريكي (USD)';
      case '₦':
        return 'النيجيرة النيجيري';
      case 'SYP':
        return 'الليرة السورية';
      case '€':
        return 'اليورو (EUR)';
      case '£':
        return 'الجنيه الإسترليني (GBP)';
      case '₹':
        return 'الروبية الهندية (INR)';
      case '₨':
        return 'الروبية الباكستانية (PKR)';
      case '৳':
        return 'التاكا البنغلاديشية (BDT)';
      case 'د.إ':
        return 'الدرهم الإماراتي (AED)';
      case '﷼':
        return 'الريال السعودي (SAR)';
      case '¥':
        return 'الين الياباني (JPY)';
      case '₩':
        return 'الوون الكوري (KRW)';
      default:
        return symbol;
    }
  }

  // ── ALL EXPENSES ─────────────────────────────────────────────────────
  @override
  String get allExpenses => 'كل المصروفات';
  @override
  String get searchExpenses => 'ابحث بالعنوان أو الملاحظة';
  @override
  String get noResults => 'لا توجد نتائج مطابقة للبحث';
  @override
  String get noResultsSubtitle => 'جرّب كلمة أخرى أو امسح عوامل التصفية.';
  @override
  String get clearFilters => 'مسح عوامل التصفية';
  @override
  String get allCategories => 'الكل';
  @override
  String get loadMore => 'تحميل المزيد';
  @override
  String get filters => 'التصفية';
  @override
  String get expenseCount => 'مصروفات';

  // ── INCOME ──────────────────────────────────────────────────────────
  @override
  String get incomeHistory => 'سجل الدخل';
  @override
  String get noIncomes => 'لا يوجد دخل مسجّل';
  @override
  String get noIncomesSubtitle =>
      'أضف الراتب أو أي مبالغ استلمتها لتتبع التدفق النقدي الحقيقي.';
  @override
  String get editIncome => 'تعديل الدخل';
  @override
  String get deleteIncome => 'حذف الدخل؟';
  @override
  String get deleteIncomeBody =>
      'سيؤدي هذا إلى إزالة القيد وخصم المبلغ من رصيدك.';
  @override
  String get incomeDeleted => 'تم حذف الدخل';
  @override
  String get incomeUpdated => 'تم تحديث الدخل';
  @override
  String get incomeThisMonth => 'دخل هذا الشهر';
  @override
  String get netFlowThisMonth => 'الصافي هذا الشهر';

  // ── BUDGETS ─────────────────────────────────────────────────────────
  @override
  String get budgets => 'الميزانيات الشهرية';
  @override
  String get budgetFor => 'ميزانية';
  @override
  String get setBudget => 'تعيين الميزانية';
  @override
  String get budgetUpdated => 'تم تحديث الميزانية';
  @override
  String get noBudgets => 'لا توجد ميزانيات بعد';
  @override
  String get noBudgetsSubtitle =>
      'حدّد سقفًا شهريًا لكلفئة وسيُعلمك GExpenses عند الاقتراب من الحد.';
  @override
  String get overBudget => 'تجاوز الميزانية';
  @override
  String get nearLimit => 'اقترب من الحد';
  @override
  String get spentLabel => 'مُنفق';
  @override
  String get remainingLabel => 'متبقي';
  @override
  String get removeBudget => 'إزالة الميزانية';
  @override
  String get budgetRemoveHint => 'أدخل 0 لإزالة هذه الميزانية';

  // ── DATA & BACKUP ─────────────────────────────────────────────────────
  @override
  String get dataAndBackup => 'البيانات والنسخ الاحتياطي';
  @override
  String get exportCsv => 'تصدير كـ CSV';
  @override
  String get exportJson => 'تصدير كـ JSON';
  @override
  String get importBackup => 'استيراد من ملف';
  @override
  String get exportReady => 'تم إنشاء النسخة الاحتياطية';
  @override
  String get exportFailed => 'تعذّر إنشاء النسخة الاحتياطية';
  @override
  String importDone(int imported) => 'تم استيراد $imported مصروفات';
  @override
  String importSkipped(int skipped) => 'تم تخطي $skipped صفوف';
  @override
  String get importEmpty => 'لم يتم العثور على مصروفات صالحة في ذلك الملف';
  @override
  String get importFailed => 'تعذّرت قراءة ذلك الملف';
  @override
  String get importBalanceNote =>
      'تُضاف المصروفات المستوردة إلى سجلك. لن يتغير رصيدك الحالي.';
  @override
  String get resetData => 'مسح جميع البيانات';
  @override
  String get resetDataTitle => 'مسح كل شيء؟';
  @override
  String get resetDataBody =>
      'سيؤدي هذا إلى حذف كل مصروف ودخل وميزانية ورصيدك نهائيًا. صدّر نسخة '
      'احتياطية أولًا إذا كنت قد تحتاج هذه البيانات.';
  @override
  String get resetDataConfirm => 'مسح';
  @override
  String get dataReset => 'تم مسح جميع البيانات';

  // ── DATES ────────────────────────────────────────────────────────────
  @override
  String daysAgo(int days) {
    if (days == 2) return 'قبل يومين';
    if (days >= 3 && days <= 10) return 'قبل $days أيام';
    return 'قبل $days يومًا';
  }

  /// Formats with the `ar` locale, falling back to the default locale when
  /// the Arabic date symbols have not been initialized (they are registered
  /// by `GlobalMaterialLocalizations` in `main.dart`).
  String _arDate(String pattern, DateTime date) {
    try {
      return DateFormat(pattern, 'ar').format(date);
    } catch (_) {
      return DateFormat(pattern).format(date);
    }
  }

  @override
  String headerDate(DateTime date) => _arDate('EEEE, MMMM d', date);

  @override
  String formatDate(DateTime date) => _arDate('EEE, MMM d, yyyy', date);

  @override
  String formatShortDate(DateTime date) => _arDate('MMM d, yyyy', date);

  @override
  String formatMonthYear(DateTime date) => _arDate('MMMM yyyy', date);

  @override
  String formatDateTime(DateTime date) =>
      _arDate('EEE, MMM d, yyyy · h:mm a', date);

  @override
  String weekdayShort(DateTime date) => _arDate('E', date);

  @override
  String monthInitial(int month) {
    const initials = [
      'ي', // يناير
      'ف', // فبراير
      'م', // مارس
      'أ', // أبريل
      'م', // مايو
      'ي', // يونيو
      'ي', // يوليو
      'أ', // أغسطس
      'س', // سبتمبر
      'أ', // أكتوبر
      'ن', // نوفمبر
      'د', // ديسمبر
    ];
    return initials[(month - 1).clamp(0, 11)];
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ar';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      locale.languageCode == 'ar'
          ? const AppLocalizationsAr()
          : const AppLocalizations();

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
