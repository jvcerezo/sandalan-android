/// Model for quick-add expense templates stored locally in SharedPreferences.

class ExpenseTemplate {
  final String id;
  final String name;
  final double amount;
  final String category;
  final String? accountId;
  final String? description;
  final int useCount;
  final DateTime lastUsed;

  const ExpenseTemplate({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    this.accountId,
    this.description,
    this.useCount = 0,
    required this.lastUsed,
  });

  factory ExpenseTemplate.fromJson(Map<String, dynamic> json) {
    return ExpenseTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      accountId: json['accountId'] as String?,
      description: json['description'] as String?,
      useCount: json['useCount'] as int? ?? 0,
      lastUsed: DateTime.tryParse(json['lastUsed'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'category': category,
    'accountId': accountId,
    'description': description,
    'useCount': useCount,
    'lastUsed': lastUsed.toIso8601String(),
  };

  ExpenseTemplate copyWith({
    String? name,
    double? amount,
    String? category,
    String? accountId,
    String? description,
    int? useCount,
    DateTime? lastUsed,
  }) {
    return ExpenseTemplate(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      description: description ?? this.description,
      useCount: useCount ?? this.useCount,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}
