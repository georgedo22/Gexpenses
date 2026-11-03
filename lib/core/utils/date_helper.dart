import 'package:intl/intl.dart';

/// Utility for human-friendly date formatting.
class DateHelper {
  DateHelper._();

  /// Returns a relative label for [date], e.g. "Today", "Yesterday",
  /// "3 days ago", or a formatted date for anything older.
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff < 7) return '$diff days ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Short weekday label, e.g. "Mon".
  static String weekdayLabel(DateTime date) => DateFormat('EEE').format(date);

  /// Short date label, e.g. "Oct 30".
  static String shortDate(DateTime date) => DateFormat('MMM d').format(date);

  /// Full date label, e.g. "Monday, Oct 30, 2026".
  static String fullDate(DateTime date) =>
      DateFormat('EEEE, MMM d, yyyy').format(date);

  /// Month label, e.g. "October 2026".
  static String monthLabel(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);
}
