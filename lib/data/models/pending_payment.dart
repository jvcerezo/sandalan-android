/// A pending payment auto-generated at the start of each billing period.
/// The user can edit the amount and confirm to create a real transaction.

class PendingPayment {
  final String id;
  final String userId;
  final String createdAt;

  /// 'bill' | 'debt' | 'insurance' | 'contribution'
  final String sourceType;

  /// The id of the bill / debt / insurance policy / contribution type this came from.
  final String sourceId;

  /// Display name (e.g. "Electricity", "Credit Card", "SSS")
  final String name;

  /// YYYY-MM period this pending payment covers.
  final String period;

  /// Pre-filled default amount (user can edit before confirming).
  final double defaultAmount;

  /// 'pending' | 'confirmed'
  final String status;

  /// Optional: the account to deduct from (pre-filled from the source).
  final String? accountId;

  /// Optional note.
  final String? notes;

  const PendingPayment({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.sourceType,
    required this.sourceId,
    required this.name,
    required this.period,
    required this.defaultAmount,
    required this.status,
    this.accountId,
    this.notes,
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'created_at': createdAt,
        'source_type': sourceType,
        'source_id': sourceId,
        'name': name,
        'period': period,
        'default_amount': defaultAmount,
        'status': status,
        'account_id': accountId,
        'notes': notes,
      };

  factory PendingPayment.fromMap(Map<String, dynamic> map) {
    return PendingPayment(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      createdAt: map['created_at'] as String,
      sourceType: map['source_type'] as String,
      sourceId: map['source_id'] as String,
      name: map['name'] as String,
      period: map['period'] as String,
      defaultAmount: (map['default_amount'] as num).toDouble(),
      status: map['status'] as String? ?? 'pending',
      accountId: map['account_id'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
