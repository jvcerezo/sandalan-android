/// Debt model — port of Debt interface from database.ts

class Debt {
  final String id;
  final String userId;
  final String createdAt;
  final String name;
  final String type; // credit_card | personal_loan | sss_loan | pagibig_loan | home_loan | car_loan | salary_loan | other
  final String? lender;
  final double currentBalance;
  final double originalAmount;
  final double interestRate; // annual rate as decimal (0.24 = 24%)
  final double minimumPayment;
  final int? dueDay; // 1-31
  final bool isPaidOff;
  final String? notes;
  final String? accountId;

  const Debt({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.name,
    required this.type,
    this.lender,
    required this.currentBalance,
    required this.originalAmount,
    required this.interestRate,
    required this.minimumPayment,
    this.dueDay,
    required this.isPaidOff,
    this.notes,
    this.accountId,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      createdAt: json['created_at'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      lender: json['lender'] as String?,
      currentBalance: (json['current_balance'] as num).toDouble(),
      originalAmount: (json['original_amount'] as num).toDouble(),
      interestRate: (json['interest_rate'] as num).toDouble(),
      minimumPayment: (json['minimum_payment'] as num).toDouble(),
      dueDay: json['due_day'] as int?,
      isPaidOff: json['is_paid_off'] as bool? ?? false,
      notes: json['notes'] as String?,
      accountId: json['account_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'created_at': createdAt,
        'name': name,
        'type': type,
        'lender': lender,
        'current_balance': currentBalance,
        'original_amount': originalAmount,
        'interest_rate': interestRate,
        'minimum_payment': minimumPayment,
        'due_day': dueDay,
        'is_paid_off': isPaidOff,
        'notes': notes,
        'account_id': accountId,
      };

  double get interestRatePercent => interestRate * 100;
}
