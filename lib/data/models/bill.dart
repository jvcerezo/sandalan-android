/// Bill model — port of Bill interface from database.ts

class Bill {
  final String id;
  final String userId;
  final String createdAt;
  final String name;
  final String category; // electricity | water | internet | mobile | cable_tv | rent | association_dues | streaming | software | gym | other
  final double amount;
  final String billingCycle; // monthly | quarterly | semi_annual | annual
  final int? dueDay; // 1-31
  final String? provider;
  final String? lastPaidDate;
  final bool isActive;
  final String? notes;
  final String? accountId;

  const Bill({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.name,
    required this.category,
    required this.amount,
    required this.billingCycle,
    this.dueDay,
    this.provider,
    this.lastPaidDate,
    required this.isActive,
    this.notes,
    this.accountId,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      createdAt: json['created_at'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      billingCycle: json['billing_cycle'] as String,
      dueDay: json['due_day'] as int?,
      provider: json['provider'] as String?,
      lastPaidDate: json['last_paid_date'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      accountId: json['account_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'created_at': createdAt,
        'name': name,
        'category': category,
        'amount': amount,
        'billing_cycle': billingCycle,
        'due_day': dueDay,
        'provider': provider,
        'last_paid_date': lastPaidDate,
        'is_active': isActive,
        'notes': notes,
        'account_id': accountId,
      };
}
