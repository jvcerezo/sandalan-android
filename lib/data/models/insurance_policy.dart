/// Insurance policy model — port of InsurancePolicy interface from database.ts

class InsurancePolicy {
  final String id;
  final String userId;
  final String createdAt;
  final String name;
  final String type; // life | health | hmo | car | property | ctpl | other
  final String? provider;
  final String? policyNumber;
  final double premiumAmount;
  final String premiumFrequency; // monthly | quarterly | semi_annual | annual
  final double? coverageAmount;
  final String? renewalDate;
  final bool isActive;
  final String? notes;
  final String? accountId;

  const InsurancePolicy({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.name,
    required this.type,
    this.provider,
    this.policyNumber,
    required this.premiumAmount,
    required this.premiumFrequency,
    this.coverageAmount,
    this.renewalDate,
    required this.isActive,
    this.notes,
    this.accountId,
  });

  factory InsurancePolicy.fromJson(Map<String, dynamic> json) {
    return InsurancePolicy(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      createdAt: json['created_at'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      provider: json['provider'] as String?,
      policyNumber: json['policy_number'] as String?,
      premiumAmount: (json['premium_amount'] as num).toDouble(),
      premiumFrequency: json['premium_frequency'] as String,
      coverageAmount: (json['coverage_amount'] as num?)?.toDouble(),
      renewalDate: json['renewal_date'] as String?,
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
        'type': type,
        'provider': provider,
        'policy_number': policyNumber,
        'premium_amount': premiumAmount,
        'premium_frequency': premiumFrequency,
        'coverage_amount': coverageAmount,
        'renewal_date': renewalDate,
        'is_active': isActive,
        'notes': notes,
        'account_id': accountId,
      };
}
