/// Account model — port of Account interface from database.ts

class Account {
  final String id;
  final String createdAt;
  final String userId;
  final String name;
  final String type;
  final String currency;
  final double balance;
  final bool isArchived;

  const Account({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.name,
    required this.type,
    required this.currency,
    required this.balance,
    required this.isArchived,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      currency: json['currency'] as String,
      balance: (json['balance'] as num).toDouble(),
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt,
        'user_id': userId,
        'name': name,
        'type': type,
        'currency': currency,
        'balance': balance,
        'is_archived': isArchived,
      };
}
