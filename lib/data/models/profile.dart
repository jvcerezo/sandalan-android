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
  final String? lifeStage; // e.g. 'unang-hakbang', 'pundasyon', etc.
  final String? userType; // e.g. 'employee', 'freelancer', 'student', etc.
  final List<String> focusAreas; // e.g. ['track-expenses', 'budget-salary']
  final List<String> checklistDone;
  final List<String> checklistSkipped;
  final List<String> guidesRead;

  const Profile({
    required this.id,
    this.email,
    this.fullName,
    required this.role,
    required this.createdAt,
    required this.primaryCurrency,
    required this.hasCompletedOnboarding,
    this.avatarUrl,
    this.lifeStage,
    this.userType,
    this.focusAreas = const [],
    this.checklistDone = const [],
    this.checklistSkipped = const [],
    this.guidesRead = const [],
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
      lifeStage: json['life_stage'] as String?,
      userType: json['user_type'] as String?,
      focusAreas: (json['focus_areas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      checklistDone: (json['checklist_done'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      checklistSkipped: (json['checklist_skipped'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      guidesRead: (json['guides_read'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
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
        'life_stage': lifeStage,
        'user_type': userType,
        'focus_areas': focusAreas,
        'checklist_done': checklistDone,
        'checklist_skipped': checklistSkipped,
        'guides_read': guidesRead,
      };

  Profile copyWith({
    String? lifeStage,
    String? userType,
    List<String>? focusAreas,
    List<String>? checklistDone,
    List<String>? checklistSkipped,
    List<String>? guidesRead,
  }) {
    return Profile(
      id: id,
      email: email,
      fullName: fullName,
      role: role,
      createdAt: createdAt,
      primaryCurrency: primaryCurrency,
      hasCompletedOnboarding: hasCompletedOnboarding,
      avatarUrl: avatarUrl,
      lifeStage: lifeStage ?? this.lifeStage,
      userType: userType ?? this.userType,
      focusAreas: focusAreas ?? this.focusAreas,
      checklistDone: checklistDone ?? this.checklistDone,
      checklistSkipped: checklistSkipped ?? this.checklistSkipped,
      guidesRead: guidesRead ?? this.guidesRead,
    );
  }

  String get firstName => fullName?.split(' ').first ?? '';
  bool get isAdmin => role == 'admin';
}
