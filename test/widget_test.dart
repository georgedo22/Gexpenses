import 'package:flutter_test/flutter_test.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/data/models/expense.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';

void main() {
  group('Expense model', () {
    test('toMap / fromMap round trip preserves data', () {
      final expense = Expense(
        id: 1,
        amount: 42.5,
        title: 'Lunch',
        category: ExpenseCategory.food,
        dateTime: DateTime(2026, 10, 30, 12, 30),
        note: 'Team lunch',
      );

      final map = expense.toMap();
      expect(map['amount_cents'], 4250);
      expect(map['title'], 'Lunch');
      expect(map['category'], 'food');
      expect(map['note'], 'Team lunch');

      final restored = Expense.fromMap(map);
      expect(restored.amount, expense.amount);
      expect(restored.title, expense.title);
      expect(restored.category, expense.category);
      expect(restored.dateTime, expense.dateTime);
      expect(restored.note, expense.note);
    });

    test('copyWith updates fields', () {
      final expense = Expense(
        amount: 10,
        title: 'Bus',
        category: ExpenseCategory.transport,
        dateTime: DateTime(2026, 10, 30),
      );

      final updated = expense.copyWith(
        amount: 20,
        title: 'Train',
        category: ExpenseCategory.transport,
      );

      expect(updated.amount, 20);
      expect(updated.title, 'Train');
      expect(updated.category, ExpenseCategory.transport);
      expect(updated.dateTime, expense.dateTime);
    });
  });

  group('CurrencyFormatter', () {
    test('formats amounts with currency symbol', () {
      expect(CurrencyFormatter.format(1234.5), contains('1,234.50'));
      expect(CurrencyFormatter.format(1234.5), startsWith(r'$'));
    });

    test('formats compact amounts', () {
      expect(CurrencyFormatter.formatCompact(1200), contains('1.2k'));
      expect(CurrencyFormatter.formatCompact(25), contains('25.00'));
    });
  });
}
