import 'dart:convert';

class SplitParticipant {
  final String name;
  final double share;
  final bool isPaid;

  const SplitParticipant({
    required this.name,
    required this.share,
    this.isPaid = false,
  });

  factory SplitParticipant.fromJson(Map<String, dynamic> json) {
    return SplitParticipant(
      name: json['name'] as String,
      share: (json['share'] as num).toDouble(),
      isPaid: json['isPaid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'share': share,
    'isPaid': isPaid,
  };

  SplitParticipant copyWith({String? name, double? share, bool? isPaid}) {
    return SplitParticipant(
      name: name ?? this.name,
      share: share ?? this.share,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

class BillSplit {
  final String id;
  final String userId;
  final String description;
  final double totalAmount;
  final String splitMethod; // 'equal', 'custom'
  final List<SplitParticipant> participants;
  final bool isSettled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BillSplit({
    required this.id,
    required this.userId,
    required this.description,
    required this.totalAmount,
    this.splitMethod = 'equal',
    required this.participants,
    this.isSettled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BillSplit.fromMap(Map<String, dynamic> map) {
    List<SplitParticipant> participants = [];
    final pStr = map['participants'] as String? ?? '[]';
    try {
      final pList = (jsonDecode(pStr) as List).cast<Map<String, dynamic>>();
      participants = pList.map((p) => SplitParticipant.fromJson(p)).toList();
    } catch (_) {}

    return BillSplit(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      description: map['description'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      splitMethod: map['split_method'] as String? ?? 'equal',
      participants: participants,
      isSettled: (map['is_settled'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'description': description,
    'total_amount': totalAmount,
    'split_method': splitMethod,
    'participants': jsonEncode(participants.map((p) => p.toJson()).toList()),
    'is_settled': isSettled ? 1 : 0,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'sync_status': 'pending',
  };

  BillSplit copyWith({
    String? description,
    double? totalAmount,
    String? splitMethod,
    List<SplitParticipant>? participants,
    bool? isSettled,
  }) {
    return BillSplit(
      id: id,
      userId: userId,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      splitMethod: splitMethod ?? this.splitMethod,
      participants: participants ?? this.participants,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Calculate how much "You" are owed (sum of unpaid, non-You shares).
  double get amountOwed {
    double owed = 0;
    for (final p in participants) {
      if (p.name != 'You' && !p.isPaid) {
        owed += p.share;
      }
    }
    return owed;
  }

  int get paidCount => participants.where((p) => p.isPaid || p.name == 'You').length;

  /// Generate shareable nudge text.
  String nudgeText() {
    final unpaid = participants.where((p) => p.name != 'You' && !p.isPaid).toList();
    if (unpaid.isEmpty) return 'Everyone has paid for "$description"!';
    final names = unpaid.map((p) => '${p.name} (\u20b1${p.share.toStringAsFixed(0)})').join(', ');
    return 'Hey! Reminder for "$description" (\u20b1${totalAmount.toStringAsFixed(0)} total). Still pending: $names. Salamat!';
  }
}
