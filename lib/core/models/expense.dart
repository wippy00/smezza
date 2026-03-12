class Expense {
  final int? id;
  final String title;
  final double amount;
  final String description;
  final DateTime date;
  final String category;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.description,
    required this.date,
    this.category = 'Generale',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'category': category,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      category: map['category'] ?? 'Generale',
    );
  }
}
