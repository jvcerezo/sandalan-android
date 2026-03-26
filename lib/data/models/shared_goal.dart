import 'dart:convert';

/// A contributor to a shared goal.
class GoalContributor {
  final String name;
  final double pledged;  // How much they committed to contribute
  final double contributed; // How much they've actually put in
  final bool isOwner; // The person who created the goal

  const GoalContributor({
    required this.name,
    this.pledged = 0,
    this.contributed = 0,
    this.isOwner = false,
  });

  factory GoalContributor.fromJson(Map<String, dynamic> json) => GoalContributor(
    name: json['name'] as String,
    pledged: (json['pledged'] as num?)?.toDouble() ?? 0,
    contributed: (json['contributed'] as num?)?.toDouble() ?? 0,
    isOwner: json['isOwner'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'pledged': pledged,
    'contributed': contributed,
    'isOwner': isOwner,
  };

  GoalContributor copyWith({
    String? name,
    double? pledged,
    double? contributed,
    bool? isOwner,
  }) => GoalContributor(
    name: name ?? this.name,
    pledged: pledged ?? this.pledged,
    contributed: contributed ?? this.contributed,
    isOwner: isOwner ?? this.isOwner,
  );
}

/// A shared savings goal where multiple people contribute toward a target.
class SharedGoal {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final double targetAmount;
  final List<GoalContributor> contributors;
  final DateTime deadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SharedGoal({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.targetAmount,
    required this.contributors,
    required this.deadline,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalContributed =>
      contributors.fold<double>(0, (sum, c) => sum + c.contributed);

  double get totalPledged =>
      contributors.fold<double>(0, (sum, c) => sum + c.pledged);

  double get progress => targetAmount > 0
      ? (totalContributed / targetAmount).clamp(0, 1)
      : 0;

  bool get isCompleted => totalContributed >= targetAmount;

  int get daysRemaining => deadline.difference(DateTime.now()).inDays;

  /// How much more is needed per contributor to reach target by deadline.
  double get perPersonNeeded {
    final remaining = targetAmount - totalContributed;
    if (remaining <= 0 || contributors.isEmpty) return 0;
    return remaining / contributors.length;
  }

  factory SharedGoal.fromMap(Map<String, dynamic> map) {
    List<GoalContributor> contributors = [];
    final cStr = map['contributors'] as String? ?? '[]';
    try {
      final cList = (jsonDecode(cStr) as List).cast<Map<String, dynamic>>();
      contributors = cList.map((c) => GoalContributor.fromJson(c)).toList();
    } catch (_) {}

    return SharedGoal(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      targetAmount: (map['target_amount'] as num).toDouble(),
      contributors: contributors,
      deadline: DateTime.tryParse(map['deadline'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'description': description,
    'target_amount': targetAmount,
    'contributors': jsonEncode(contributors.map((c) => c.toJson()).toList()),
    'deadline': deadline.toIso8601String().substring(0, 10),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'sync_status': 'pending',
  };

  SharedGoal copyWith({
    String? name,
    String? description,
    double? targetAmount,
    List<GoalContributor>? contributors,
    DateTime? deadline,
  }) => SharedGoal(
    id: id,
    userId: userId,
    name: name ?? this.name,
    description: description ?? this.description,
    targetAmount: targetAmount ?? this.targetAmount,
    contributors: contributors ?? this.contributors,
    deadline: deadline ?? this.deadline,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  /// Generate shareable invite text.
  String shareText() {
    final remaining = targetAmount - totalContributed;
    return 'Join our shared savings goal "$name"! '
        'Target: \u20b1${targetAmount.toStringAsFixed(0)}, '
        '${contributors.length} contributors, '
        '\u20b1${remaining.toStringAsFixed(0)} left to go. '
        'Download Sandalan to track your contribution!';
  }
}
