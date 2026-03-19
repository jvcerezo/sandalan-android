/// Government contribution model — port of Contribution interface from database.ts

class Contribution {
  final String id;
  final String userId;
  final String createdAt;
  final String type; // sss | philhealth | pagibig
  final String period; // YYYY-MM
  final double monthlySalary;
  final double employeeShare;
  final double? employerShare;
  final double totalContribution;
  final bool isPaid;
  final String employmentType; // employed | self_employed | voluntary | ofw
  final String? notes;

  const Contribution({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.type,
    required this.period,
    required this.monthlySalary,
    required this.employeeShare,
    this.employerShare,
    required this.totalContribution,
    required this.isPaid,
    required this.employmentType,
    this.notes,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      createdAt: json['created_at'] as String,
      type: json['type'] as String,
      period: json['period'] as String,
      monthlySalary: (json['monthly_salary'] as num).toDouble(),
      employeeShare: (json['employee_share'] as num).toDouble(),
      employerShare: (json['employer_share'] as num?)?.toDouble(),
      totalContribution: (json['total_contribution'] as num).toDouble(),
      isPaid: json['is_paid'] as bool? ?? false,
      employmentType: json['employment_type'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'created_at': createdAt,
        'type': type,
        'period': period,
        'monthly_salary': monthlySalary,
        'employee_share': employeeShare,
        'employer_share': employerShare,
        'total_contribution': totalContribution,
        'is_paid': isPaid,
        'employment_type': employmentType,
        'notes': notes,
      };
}
