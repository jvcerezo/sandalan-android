/// Checklist progress model for adulting guide.

class ChecklistProgress {
  final String userId;
  final String itemId;
  final String status; // done | skipped
  final String? completedAt;

  const ChecklistProgress({
    required this.userId,
    required this.itemId,
    required this.status,
    this.completedAt,
  });

  factory ChecklistProgress.fromJson(Map<String, dynamic> json) {
    return ChecklistProgress(
      userId: json['user_id'] as String,
      itemId: json['item_id'] as String,
      status: json['status'] as String,
      completedAt: json['completed_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'item_id': itemId,
        'status': status,
        'completed_at': completedAt,
      };

  bool get isDone => status == 'done';
  bool get isSkipped => status == 'skipped';
}
