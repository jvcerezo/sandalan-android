class Investment {
  final String id;
  final String userId;
  final String name;
  final String type;
  final double amountInvested;
  final double currentValue;
  final String? accountId;
  final DateTime dateStarted;
  final String? notes;
  final String? navpu;
  final double? units;
  final double? interestRate;
  final DateTime? maturityDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  const Investment({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.amountInvested,
    this.currentValue = 0,
    this.accountId,
    required this.dateStarted,
    this.notes,
    this.navpu,
    this.units,
    this.interestRate,
    this.maturityDate,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
  });

  double get gainLoss => currentValue - amountInvested;
  double get gainLossPercent =>
      amountInvested > 0 ? (gainLoss / amountInvested) * 100 : 0;
  bool get isPositive => gainLoss >= 0;

  String get typeLabel {
    switch (type) {
      case 'mp2': return 'Pag-IBIG MP2';
      case 'uitf': return 'UITF';
      case 'mutual_fund': return 'Mutual Fund';
      case 'stocks': return 'Stocks (PSE)';
      case 'bonds': return 'Bonds / RTB';
      case 'time_deposit': return 'Time Deposit';
      case 'digital': return 'Digital Investment';
      case 'crypto': return 'Crypto';
      case 'real_estate': return 'Real Estate';
      default: return 'Other';
    }
  }

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    amountInvested: (json['amount_invested'] as num).toDouble(),
    currentValue: (json['current_value'] as num?)?.toDouble() ?? 0,
    accountId: json['account_id'] as String?,
    dateStarted: DateTime.parse(json['date_started'] as String),
    notes: json['notes'] as String?,
    navpu: json['navpu'] as String?,
    units: (json['units'] as num?)?.toDouble(),
    interestRate: (json['interest_rate'] as num?)?.toDouble(),
    maturityDate: json['maturity_date'] != null
        ? DateTime.tryParse(json['maturity_date'] as String)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    syncStatus: json['sync_status'] as String? ?? 'synced',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'name': name, 'type': type,
    'amount_invested': amountInvested, 'current_value': currentValue,
    'account_id': accountId, 'date_started': dateStarted.toIso8601String(),
    'notes': notes, 'navpu': navpu, 'units': units,
    'interest_rate': interestRate,
    'maturity_date': maturityDate?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'sync_status': syncStatus,
  };
}
