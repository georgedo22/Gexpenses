import 'package:intl/intl.dart';

/// Utility for formatting currency amounts.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Current currency symbol, set at startup and changed from Settings.
  static String symbol = r'$';

  static final Map<String, NumberFormat> _formatters = {};

  /// Returns a cached formatter for the current symbol.
  static NumberFormat _formatter() => _formatters.putIfAbsent(
        symbol,
        () => NumberFormat.currency(symbol: symbol, decimalDigits: 2),
      );

  /// Formats [amount] as a currency string, e.g. `$1,234.50`.
  static String format(double amount) => _formatter().format(amount);

  /// Formats [amount] compactly, e.g. `$1.2k` for 1200.
  static String formatCompact(double amount) {
    if (amount.abs() >= 1000) {
      final thousands = amount / 1000;
      final value = thousands.abs() >= 100
          ? thousands.toStringAsFixed(0)
          : thousands.toStringAsFixed(1);
      return '${amount < 0 ? '-' : ''}$symbol$value${'k'}';
    }
    return _formatter().format(amount);
  }
}
