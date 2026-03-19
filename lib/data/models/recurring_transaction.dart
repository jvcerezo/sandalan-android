/// Recurring transaction model — port from database.ts

class RecurringTransaction {
  final String id;
  final String createdAt;
  final String userId;
  final double amount;
  final String category;
  final String? description;
  final String currency;
  final String? accountId;
  final String frequency; // daily | weekly | monthly
  final int intervalCount;
  final String startDate;
  final String? endDate;
  final String nextRunDate;
  final String? lastRunDate;
  final String? runTime;
  final bool isActive;
  final List<String>? tags;

  const RecurringTransaction({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.amount,
    required this.category,
    this.description,
    required this.currency,
    this.accountId,
    required this.frequency,
    required this.intervalCount,
    required this.startDate,
    this.endDate,
    required this.nextRunDate,
    this.lastRunDate,
    this.runTime,
    required this.isActive,
    this.tags,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String?,
      currency: json['currency'] as String,
      accountId: json['account_id'] as String?,
      frequency: json['frequency'] as String,
      intervalCount: json['interval_count'] as int? ?? 1,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String?,
      nextRunDate: json['next_run_date'] as String,
      lastRunDate: json['last_run_date'] as String?,
      runTime: json['run_time'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt,
        'user_id': userId,
        'amount': amount,
        'category': category,
        'description': description,
        'currency': currency,
        'account_id': accountId,
        'frequency': frequency,
        'interval_count': intervalCount,
        'start_date': startDate,
        'end_date': endDate,
        'next_run_date': nextRunDate,
        'last_run_date': lastRunDate,
        'run_time': runTime,
        'is_active': isActive,
        'tags': tags,
      };
}
