/// Transaction model — port of Transaction interface from database.ts

class Transaction {
  final String id;
  final String createdAt;
  final String userId;
  final double amount;
  final String category;
  final String description;
  final String date;
  final String currency;
  final String? attachmentPath;
  final String? accountId;
  final String? transferId;
  final String? splitGroupId;
  final List<String>? tags;
  final String status; // 'confirmed' | 'pending'

  const Transaction({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.currency,
    this.attachmentPath,
    this.accountId,
    this.transferId,
    this.splitGroupId,
    this.tags,
    this.status = 'confirmed',
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String,
      date: json['date'] as String,
      currency: json['currency'] as String,
      attachmentPath: json['attachment_path'] as String?,
      accountId: json['account_id'] as String?,
      transferId: json['transfer_id'] as String?,
      splitGroupId: json['split_group_id'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      status: json['status'] as String? ?? 'confirmed',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt,
        'user_id': userId,
        'amount': amount,
        'category': category,
        'description': description,
        'date': date,
        'currency': currency,
        'attachment_path': attachmentPath,
        'account_id': accountId,
        'transfer_id': transferId,
        'split_group_id': splitGroupId,
        'tags': tags,
        'status': status,
      };

  bool get isIncome => amount > 0;
  bool get isExpense => amount < 0;
  bool get isTransfer => transferId != null;
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
}
