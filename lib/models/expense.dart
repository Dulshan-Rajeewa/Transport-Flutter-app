class Expense {
  final String? id;
  final String type;
  final double amount;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAutomatic;

  Expense({
    this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.isAutomatic = false,
  });

  factory Expense.fromFirestore(Map<String, dynamic> data, String id) {
    final now = DateTime.now();
    return Expense(
      id: id,
      type: data['type'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'],
      date: data['date'] != null ? (data['date'] as dynamic).toDate() : now,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as dynamic).toDate() : now,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as dynamic).toDate() : now,
      isAutomatic: data['isAutomatic'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'amount': amount,
      'description': description,
      'date': date,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isAutomatic': isAutomatic,
    };
  }
}
