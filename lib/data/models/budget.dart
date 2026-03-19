/// Budget model — port of Budget interface from database.ts

class Budget {
  final String id;
  final String createdAt;
  final String userId;
  final String category;
  final double amount;
  final String month; // YYYY-MM
  final String period; // weekly | monthly | quarterly
  final bool rollover;

  const Budget({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.category,
    required this.amount,
    required this.month,
    required this.period,
    required this.rollover,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      month: json['month'] as String,
      period: json['period'] as String? ?? 'monthly',
      rollover: json['rollover'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt,
        'user_id': userId,
        'category': category,
        'amount': amount,
        'month': month,
        'period': period,
        'rollover': rollover,
      };
}
