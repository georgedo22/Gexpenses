import 'package:gexpenses/domain/enums/expense_category.dart';

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

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'amount': amount,
      'title': title,
      'category': category.name,
      'date_time': dateTime.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    if (note != null) {
      map['note'] = note;
    }
    return map;
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      title: map['title'] as String,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'] as String?,
        orElse: () => ExpenseCategory.other,
      ),
      dateTime: DateTime.parse(map['date_time'] as String),
      note: map['note'] as String?,
    );
  }

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
    return other is Expense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
