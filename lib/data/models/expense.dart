import 'package:gexpenses/domain/enums/expense_category.dart';

/// A single expense. `amount` is a major-unit value (e.g. 12.50) while the
/// database stores it as integer cents via [toMap].
class Expense {
  final int? id;
  final double amount;
  final String title;
  final ExpenseCategory category;
  final DateTime dateTime;
  final String? note;

  const Expense({
    this.id,
    required this.amount,
    required this.title,
    required this.category,
    required this.dateTime,
    this.note,
  });

  int get amountCents => (amount * 100).round();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'amount_cents': amountCents,
      'title': title,
      'category': category.name,
      'date_time': dateTime.toIso8601String(),
      // Always written (even when null) so clearing a note on edit really
      // clears it in the database instead of keeping the previous value.
      'note': note,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final cents = map['amount_cents'] as num?;
    return Expense(
      id: map['id'] as int?,
      amount: cents != null
          ? cents.toInt() / 100
          : (map['amount'] as num?)?.toDouble() ?? 0,
      title: map['title'] as String,
      category: ExpenseCategory.fromName(map['category'] as String?),
      dateTime: DateTime.parse(map['date_time'] as String),
      note: map['note'] as String?,
    );
  }

  /// Builds an expense from a decrypted/imported JSON object (`amount` may be
  /// either major units under `amount` or minor units under `amount_cents`).
  factory Expense.fromJson(Map<String, dynamic> json) {
    final cents = json['amount_cents'] as num?;
    return Expense(
      amount: cents != null
          ? cents.toInt() / 100
          : (json['amount'] as num?)?.toDouble() ?? 0,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Expense',
      category: ExpenseCategory.fromName(json['category'] as String?),
      dateTime:
          DateTime.tryParse(json['date_time'] as String? ?? '') ??
          DateTime.now(),
      note: (json['note'] as String?)?.trim().isEmpty == true
          ? null
          : json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'amount': amount,
    'title': title,
    'category': category.name,
    'date_time': dateTime.toIso8601String(),
    'note': note,
  };

  Expense copyWith({
    int? id,
    double? amount,
    String? title,
    ExpenseCategory? category,
    DateTime? dateTime,
    String? Function()? note,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      note: note != null ? note() : this.note,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, title: $title, '
        'category: ${category.name}, dateTime: $dateTime, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Expense) return false;
    // Saved rows have a stable identity. Unsaved rows (id == null) must be
    // compared by value, otherwise every new expense would look identical.
    if (id != null || other.id != null) return id == other.id;
    return amount == other.amount &&
        title == other.title &&
        category == other.category &&
        dateTime == other.dateTime &&
        note == other.note;
  }

  @override
  int get hashCode => id != null
      ? id.hashCode
      : Object.hash(amount, title, category, dateTime, note);
}
