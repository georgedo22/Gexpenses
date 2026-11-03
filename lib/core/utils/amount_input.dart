import 'package:flutter/services.dart';

/// Converts Arabic-Indic (٠-٩) and Extended Arabic-Indic (۰-۹) digits, the
/// Arabic decimal separator (٫) and Arabic thousands separator (٬) to their
/// ASCII equivalents.
///
/// Numeric keyboards on Arabic/Persian devices emit these characters. Dart's
/// `\d` regex class and `double.tryParse` only understand ASCII, so without
/// normalizing them the input is either filtered out or fails to parse.
String normalizeAmountText(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= 0x0660 && rune <= 0x0669) {
      // Arabic-Indic ٠..٩
      buffer.writeCharCode(0x30 + rune - 0x0660);
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      // Extended Arabic-Indic ۰..۹
      buffer.writeCharCode(0x30 + rune - 0x06F0);
    } else if (rune == 0x066B) {
      // Arabic decimal separator ٫
      buffer.write('.');
    } else if (rune == 0x066C || rune == 0x00A0 || rune == 0x202F) {
      // Thousands separators / no-break spaces are dropped.
      continue;
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// Parses a user-entered amount. Accepts localized digits and ',' as a decimal
/// separator. Returns null when the text is not a finite, non-negative number.
double? parseAmountInput(String raw) {
  var text = normalizeAmountText(raw).trim();
  if (text.isEmpty) return null;
  text = text.replaceAll(',', '.').replaceAll(' ', '');
  final value = double.tryParse(text);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return value;
}

/// Keeps a text field a valid amount while never swallowing what the user
/// typed: localized digits and ',' are normalized instead of being banned, and
/// at most one decimal separator with [decimalDigits] decimals is allowed.
///
/// Using `FilteringTextInputFormatter.allow` with an anchored pattern (or with
/// escaped backslashes such as `r'^\\d'`) rejects every keystroke, which makes
/// the field look broken on device.
class AmountInputFormatter extends TextInputFormatter {
  AmountInputFormatter({this.decimalDigits = 2});

  final int decimalDigits;

  late final RegExp _pattern = RegExp('^\\d*\\.?\\d{0,$decimalDigits}\$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = normalizeAmountText(newValue.text)
        .replaceAll(',', '.')
        .replaceAll(' ', '');

    // Collapse extra decimal separators ("1.2.3" -> "1.23").
    final firstDot = text.indexOf('.');
    if (firstDot != -1) {
      final whole = text.substring(0, firstDot);
      final fraction = text.substring(firstDot + 1).replaceAll('.', '');
      text = fraction.length > decimalDigits
          ? '$whole.${fraction.substring(0, decimalDigits)}'
          : '$whole.$fraction';
    }

    if (!_pattern.hasMatch(text)) {
      // Reject only truly invalid edits (e.g. letters) and keep the caret where
      // it was instead of clearing the field.
      return oldValue;
    }

    final selection = newValue.selection;
    final baseOffset = selection.baseOffset < 0
        ? text.length
        : selection.baseOffset.clamp(0, text.length);
    final extentOffset = selection.extentOffset < 0
        ? text.length
        : selection.extentOffset.clamp(0, text.length);

    return TextEditingValue(
      text: text,
      selection: TextSelection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
      ),
    );
  }
}
