import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gexpenses/core/utils/amount_input.dart';

void main() {
  group('normalizeAmountText', () {
    test('converts Arabic-Indic digits to ASCII', () {
      expect(normalizeAmountText('١٢٣'), '123');
    });

    test('converts Extended Arabic-Indic digits to ASCII', () {
      expect(normalizeAmountText('۴۵۶'), '456');
    });

    test('converts the Arabic decimal separator', () {
      expect(normalizeAmountText('١٢٫٥'), '12.5');
    });
  });

  group('parseAmountInput', () {
    test('parses plain ASCII amounts', () {
      expect(parseAmountInput('250'), 250);
      expect(parseAmountInput(' 12.75 '), 12.75);
    });

    test('parses localized digits', () {
      expect(parseAmountInput('١٢٣٤'), 1234);
      expect(parseAmountInput('٩٫٩٩'), 9.99);
    });

    test('accepts a comma decimal separator', () {
      expect(parseAmountInput('12,5'), 12.5);
    });

    test('returns null for empty or invalid text', () {
      expect(parseAmountInput(''), isNull);
      expect(parseAmountInput('   '), isNull);
      expect(parseAmountInput('abc'), isNull);
      expect(parseAmountInput('1.2.3'), isNull);
    });
  });

  group('AmountInputFormatter', () {
    TextEditingValue type(String text) => TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );

    test('keeps digits that the old anchored pattern rejected', () {
      final formatter = AmountInputFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        type('123'),
      );
      expect(result.text, '123');
    });

    test('normalizes Arabic-Indic digits while typing', () {
      final formatter = AmountInputFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        type('١٢٣'),
      );
      expect(result.text, '123');
      expect(result.selection.baseOffset, 3);
    });

    test('keeps a single decimal separator and two decimals', () {
      final formatter = AmountInputFormatter();
      expect(
        formatter.formatEditUpdate(TextEditingValue.empty, type('12.3')).text,
        '12.3',
      );
      expect(
        formatter.formatEditUpdate(TextEditingValue.empty, type('12.3.4')).text,
        '12.34',
      );
      expect(
        formatter.formatEditUpdate(TextEditingValue.empty, type('12.345')).text,
        '12.34',
      );
    });

    test('rejects letters by keeping the previous value', () {
      final formatter = AmountInputFormatter();
      final oldValue = type('12');
      final result = formatter.formatEditUpdate(oldValue, type('12a'));
      expect(result.text, '12');
    });
  });
}
