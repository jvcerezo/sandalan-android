/// Goal model — port of Goal interface from database.ts

class Goal {
  final String id;
  final String createdAt;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? deadline;
  final String category;
  final String? accountId;
  final bool isCompleted;

  const Goal({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.category,
    this.accountId,
    required this.isCompleted,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      deadline: json['deadline'] as String?,
      category: json['category'] as String,
      accountId: json['account_id'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt,
        'user_id': userId,
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'deadline': deadline,
        'category': category,
        'account_id': accountId,
        'is_completed': isCompleted,
      };

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;
}
