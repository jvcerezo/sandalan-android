/// Tax record model — port of TaxRecord interface from database.ts

class TaxRecord {
  final String id;
  final String userId;
  final String createdAt;
  final int year;
  final int? quarter; // 1-4, null for annual
  final double grossIncome;
  final double deductions;
  final double taxableIncome;
  final double taxDue;
  final double amountPaid;
  final String filingType; // quarterly | annual
  final String taxpayerType; // employed | self_employed | mixed
  final String status; // draft | filed | paid
  final String? notes;

  const TaxRecord({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.year,
    this.quarter,
    required this.grossIncome,
    required this.deductions,
    required this.taxableIncome,
    required this.taxDue,
    required this.amountPaid,
    required this.filingType,
    required this.taxpayerType,
    required this.status,
    this.notes,
  });

  factory TaxRecord.fromJson(Map<String, dynamic> json) {
    return TaxRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      createdAt: json['created_at'] as String,
      year: json['year'] as int,
      quarter: json['quarter'] as int?,
      grossIncome: (json['gross_income'] as num).toDouble(),
      deductions: (json['deductions'] as num).toDouble(),
      taxableIncome: (json['taxable_income'] as num).toDouble(),
      taxDue: (json['tax_due'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      filingType: json['filing_type'] as String,
      taxpayerType: json['taxpayer_type'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'created_at': createdAt,
        'year': year,
        'quarter': quarter,
        'gross_income': grossIncome,
        'deductions': deductions,
        'taxable_income': taxableIncome,
        'tax_due': taxDue,
        'amount_paid': amountPaid,
        'filing_type': filingType,
        'taxpayer_type': taxpayerType,
        'status': status,
        'notes': notes,
      };
}
