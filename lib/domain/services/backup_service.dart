import 'dart:convert';

import 'package:gexpenses/data/models/expense.dart';
import 'package:gexpenses/data/repositories/expense_repository.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';

/// Result of an import run.
class ImportResult {
  final int imported;
  final int skipped;

  const ImportResult({required this.imported, required this.skipped});

  bool get isEmpty => imported == 0;
}

/// Builds and parses portable backups of the expense history.
///
/// Pure Dart (no plugins) so it can be unit tested and reused on every
/// platform; the UI layer decides how the produced text is shared or picked.
class BackupService {
  final ExpenseRepository _expenses;

  BackupService(this._expenses);

  static const List<String> csvHeader = [
    'date',
    'title',
    'category',
    'amount',
    'note',
  ];

  Future<String> exportCsv() async {
    final expenses = await _expenses.getAllExpenses();
    final buffer = StringBuffer()..writeln(csvHeader.join(','));

    for (final expense in expenses) {
      buffer.writeln(
        [
          _csvField(expense.dateTime.toIso8601String()),
          _csvField(expense.title),
          _csvField(expense.category.name),
          expense.amount.toStringAsFixed(2),
          _csvField(expense.note ?? ''),
        ].join(','),
      );
    }

    return buffer.toString();
  }

  Future<String> exportJson() async {
    final expenses = await _expenses.getAllExpenses();
    final payload = {
      'app': 'GExpenses',
      'format_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Imports expenses from CSV text produced by [exportCsv] (or by a
  /// spreadsheet with the same header order).
  Future<ImportResult> importCsv(String content) async {
    final rows = _parseCsv(content);
    if (rows.isEmpty) return const ImportResult(imported: 0, skipped: 0);

    // Tolerate a header row in any position: skip rows whose date is not a date
    // and whose amount is not a number.
    final expenses = <Expense>[];
    var skipped = 0;

    for (final row in rows) {
      if (row.length < 4) {
        skipped++;
        continue;
      }
      if (_looksLikeHeader(row)) continue;

      final date = DateTime.tryParse(row[0].trim());
      final title = row[1].trim();
      final category = ExpenseCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == row[2].trim().toLowerCase(),
        orElse: () => ExpenseCategory.other,
      );
      final amount = double.tryParse(row[3].trim());

      if (date == null || amount == null || amount <= 0) {
        skipped++;
        continue;
      }

      expenses.add(
        Expense(
          amount: amount,
          title: title.isEmpty ? 'Expense' : title,
          category: category,
          dateTime: date,
          note: row.length > 4 && row[4].trim().isNotEmpty
              ? row[4].trim()
              : null,
        ),
      );
    }

    return _insertAll(expenses, skipped);
  }

  Future<ImportResult> importJson(String content) async {
    final dynamic decoded = jsonDecode(content);
    final dynamic raw = decoded is Map && decoded['expenses'] != null
        ? decoded['expenses']
        : decoded;

    if (raw is! List) {
      throw const FormatException('Unsupported backup format');
    }

    final expenses = <Expense>[];
    var skipped = 0;

    for (final item in raw) {
      if (item is! Map) {
        skipped++;
        continue;
      }
      try {
        final expense = Expense.fromJson(Map<String, dynamic>.from(item));
        if (expense.amount <= 0) {
          skipped++;
          continue;
        }
        expenses.add(expense);
      } catch (_) {
        skipped++;
      }
    }

    return _insertAll(expenses, skipped);
  }

  Future<ImportResult> _insertAll(List<Expense> expenses, int skipped) async {
    if (expenses.isEmpty) {
      return ImportResult(imported: 0, skipped: skipped);
    }
    final imported = await _expenses.importExpenses(expenses);
    return ImportResult(imported: imported, skipped: skipped);
  }

  static bool _looksLikeHeader(List<String> row) =>
      row[0].trim().toLowerCase() == 'date' ||
      row[3].trim().toLowerCase() == 'amount';

  static String _csvField(String value) {
    if (value.contains(RegExp(r'[",\n\r]'))) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Minimal RFC 4180 parser: handles quoted fields, escaped quotes and
  /// newlines inside quotes.
  static List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(char);
        }
        continue;
      }

      switch (char) {
        case '"':
          inQuotes = true;
        case ',':
          row.add(field.toString());
          field.clear();
        case '\n':
          row.add(field.toString());
          field.clear();
          rows.add(row);
          row = <String>[];
        case '\r':
          break;
        default:
          field.write(char);
      }
    }

    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }

    return rows.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
  }
}
