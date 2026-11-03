import 'package:gexpenses/data/models/report_data.dart';
import 'package:gexpenses/data/repositories/balance_repository.dart';
import 'package:gexpenses/data/repositories/expense_repository.dart';

class ReportService {
  final ExpenseRepository _expenseRepo;
  final BalanceRepository _balanceRepo;

  ReportService(this._expenseRepo, this._balanceRepo);

  Future<DailyReport> getDailyReport(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final expenses = await _expenseRepo.getExpensesByDateRange(start, end);
    final total = await _expenseRepo.getTotalByDateRange(start, end);

    final prevStart = start.subtract(const Duration(days: 1));
    final prevTotal = await _expenseRepo.getTotalByDateRange(prevStart, start);

    return DailyReport(
      date: start,
      totalSpent: total,
      expenses: expenses,
      previousDayTotal: prevTotal > 0 ? prevTotal : null,
    );
  }

  Future<WeeklyReport> getWeeklyReport(DateTime anyDayInWeek) async {
    final weekStart = anyDayInWeek.subtract(
      Duration(days: anyDayInWeek.weekday - 1),
    );
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));

    final total = await _expenseRepo.getTotalByDateRange(start, end);

    // Single grouped query instead of one query per day (N+1 fix).
    final totalsByDayOfMonth = await _expenseRepo.getDailyTotals(start, end);
    final dailyBreakdown = <int, double>{
      for (var i = 0; i < 7; i++)
        i + 1: totalsByDayOfMonth[start.add(Duration(days: i)).day] ?? 0.0,
    }; // 1=Monday

    final prevStart = start.subtract(const Duration(days: 7));
    final prevTotal = await _expenseRepo.getTotalByDateRange(prevStart, start);

    return WeeklyReport(
      weekStart: start,
      weekEnd: end.subtract(const Duration(days: 1)),
      totalSpent: total,
      dailyBreakdown: dailyBreakdown,
      previousWeekTotal: prevTotal > 0 ? prevTotal : null,
    );
  }

  Future<MonthlyReport> getMonthlyReport(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final total = await _expenseRepo.getTotalByDateRange(start, end);
    final categoryBreakdown = await _expenseRepo.getCategoryTotals(start, end);
    final dailyTotals = await _expenseRepo.getDailyTotals(start, end);
    final totalIncome = await _balanceRepo.getIncomeTotal(start, end);

    final prevStart = DateTime(month.year, month.month - 1, 1);
    final prevTotal = await _expenseRepo.getTotalByDateRange(prevStart, start);

    return MonthlyReport(
      month: start,
      totalSpent: total,
      totalIncome: totalIncome,
      categoryBreakdown: categoryBreakdown,
      dailyTrend: dailyTotals,
      previousMonthTotal: prevTotal > 0 ? prevTotal : null,
    );
  }

  Future<YearlyReport> getYearlyReport(int year) async {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);

    final total = await _expenseRepo.getTotalByDateRange(start, end);
    final monthlyTotals = await _expenseRepo.getMonthlyTotals(year);
    final topCategories = await _expenseRepo.getCategoryTotals(start, end);

    final sorted = Map.fromEntries(
      topCategories.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    return YearlyReport(
      year: year,
      totalSpent: total,
      monthlyBreakdown: monthlyTotals,
      topCategories: sorted,
    );
  }

  /// Flexible report over any user-picked [start]-[end] date range,
  /// inclusive of both boundary days.
  Future<CustomReport> getCustomReport(DateTime start, DateTime end) async {
    // Normalize so both boundary days are fully included.
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(
      end.year,
      end.month,
      end.day,
    ).add(const Duration(days: 1));

    final expenses = await _expenseRepo.getExpensesByDateRange(
      normalizedStart,
      normalizedEnd,
    );
    final total = await _expenseRepo.getTotalByDateRange(
      normalizedStart,
      normalizedEnd,
    );
    final categoryBreakdown = await _expenseRepo.getCategoryTotals(
      normalizedStart,
      normalizedEnd,
    );

    // Compare against the immediately preceding period of the same length.
    final span = normalizedEnd.difference(normalizedStart);
    final prevStart = normalizedStart.subtract(span);
    final prevTotal = await _expenseRepo.getTotalByDateRange(
      prevStart,
      normalizedStart,
    );

    return CustomReport(
      start: normalizedStart,
      end: normalizedEnd.subtract(const Duration(days: 1)),
      totalSpent: total,
      expenses: expenses,
      categoryBreakdown: categoryBreakdown,
      previousPeriodTotal: prevTotal > 0 ? prevTotal : null,
    );
  }
}
