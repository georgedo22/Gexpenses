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

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'amount': amount,
      'description': description,
      'date_time': dateTime.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      dateTime: DateTime.parse(map['date_time'] as String),
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
    return other is Income && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
