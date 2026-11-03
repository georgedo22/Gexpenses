/// A single income entry. `amount` is a major-unit value, stored as cents.
class Income {
  final int? id;
  final double amount;
  final String description;
  final DateTime dateTime;

  const Income({
    this.id,
    required this.amount,
    required this.description,
    required this.dateTime,
  });

  int get amountCents => (amount * 100).round();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'amount_cents': amountCents,
      'description': description,
      'date_time': dateTime.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    final cents = map['amount_cents'] as num?;
    return Income(
      id: map['id'] as int?,
      amount: cents != null
          ? cents.toInt() / 100
          : (map['amount'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String,
      dateTime: DateTime.parse(map['date_time'] as String),
    );
  }

  Income copyWith({
    int? id,
    double? amount,
    String? description,
    DateTime? dateTime,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
    );
  }

  @override
  String toString() {
    return 'Income(id: $id, amount: $amount, description: $description, '
        'dateTime: $dateTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Income) return false;
    if (id != null || other.id != null) return id == other.id;
    return amount == other.amount &&
        description == other.description &&
        dateTime == other.dateTime;
  }

  @override
  int get hashCode =>
      id != null ? id.hashCode : Object.hash(amount, description, dateTime);
}
