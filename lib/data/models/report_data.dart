import 'package:gexpenses/data/models/expense.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';

class DailyReport {
  final DateTime date;
  final double totalSpent;
  final List<Expense> expenses;
  final double? previousDayTotal;

  const DailyReport({
    required this.date,
    required this.totalSpent,
    required this.expenses,
    this.previousDayTotal,
  });

  double? get changePercent =>
      (previousDayTotal != null && previousDayTotal! > 0)
          ? ((totalSpent - previousDayTotal!) / previousDayTotal! * 100)
          : null;
}

class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalSpent;
  final Map<int, double> dailyBreakdown; // 1=Mon..7=Sun
  final double? previousWeekTotal;

  const WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.totalSpent,
    required this.dailyBreakdown,
    this.previousWeekTotal,
  });

  double get dailyAverage => totalSpent / 7;

  double? get changePercent =>
      (previousWeekTotal != null && previousWeekTotal! > 0)
          ? ((totalSpent - previousWeekTotal!) / previousWeekTotal! * 100)
          : null;
}

class MonthlyReport {
  final DateTime month; // first day of the month
  final double totalSpent;
  final Map<ExpenseCategory, double> categoryBreakdown;
  final Map<int, double> dailyTrend; // day 1..31
  final double? previousMonthTotal;

  const MonthlyReport({
    required this.month,
    required this.totalSpent,
    required this.categoryBreakdown,
    required this.dailyTrend,
    this.previousMonthTotal,
  });

  int get daysInMonth => DateTime(month.year, month.month + 1, 0).day;

  double get dailyAverage => totalSpent / daysInMonth;

  double? get changePercent =>
      (previousMonthTotal != null && previousMonthTotal! > 0)
          ? ((totalSpent - previousMonthTotal!) / previousMonthTotal! * 100)
          : null;
}

class YearlyReport {
  final int year;
  final double totalSpent;
  final Map<int, double> monthlyBreakdown; // 1..12
  final Map<ExpenseCategory, double> topCategories;

  const YearlyReport({
    required this.year,
    required this.totalSpent,
    required this.monthlyBreakdown,
    required this.topCategories,
  });

  double get monthlyAverage => totalSpent / 12;
}

class CustomReport {
  final DateTime start;
  final DateTime end;
  final double totalSpent;
  final List<Expense> expenses;
  final Map<ExpenseCategory, double> categoryBreakdown;
  final double? previousPeriodTotal;

  const CustomReport({
    required this.start,
    required this.end,
    required this.totalSpent,
    required this.expenses,
    required this.categoryBreakdown,
    this.previousPeriodTotal,
  });

  int get dayCount =>
      DateTime(end.year, end.month, end.day)
          .difference(DateTime(start.year, start.month, start.day))
          .inDays +
      1;

  double get dailyAverage => dayCount > 0 ? totalSpent / dayCount : 0.0;

  double? get changePercent =>
      (previousPeriodTotal != null && previousPeriodTotal! > 0)
          ? ((totalSpent - previousPeriodTotal!) / previousPeriodTotal! * 100)
          : null;
}
