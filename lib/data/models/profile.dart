/// User profile model — port of Profile interface from database.ts

class Profile {
  final String id;
  final String? email;
  final String? fullName;
  final String role; // 'user' | 'admin'
  final String createdAt;
  final String primaryCurrency;
  final bool hasCompletedOnboarding;
  final String? avatarUrl;

  const Profile({
    required this.id,
    this.email,
    this.fullName,
    required this.role,
    required this.createdAt,
    required this.primaryCurrency,
    required this.hasCompletedOnboarding,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: json['created_at'] as String,
      primaryCurrency: json['primary_currency'] as String? ?? 'PHP',
      hasCompletedOnboarding: json['has_completed_onboarding'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'created_at': createdAt,
        'primary_currency': primaryCurrency,
        'has_completed_onboarding': hasCompletedOnboarding,
        'avatar_url': avatarUrl,
      };

  String get firstName => fullName?.split(' ').first ?? '';
  bool get isAdmin => role == 'admin';
}
