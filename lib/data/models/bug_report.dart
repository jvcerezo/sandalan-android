/// Bug report model — port of BugReport interface from database.ts

class BugReport {
  final String id;
  final String createdAt;
  final String userId;
  final String title;
  final String description;
  final String severity; // low | medium | high | critical
  final String status; // open | in_progress | resolved
  final String? pagePath;
  final String? userAgent;
  final String? appVersion;
  final String? resolvedAt;
  final String? resolvedBy;

  const BugReport({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    this.pagePath,
    this.userAgent,
    this.appVersion,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory BugReport.fromJson(Map<String, dynamic> json) {
    return BugReport(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      status: json['status'] as String? ?? 'open',
      pagePath: json['page_path'] as String?,
      userAgent: json['user_agent'] as String?,
      appVersion: json['app_version'] as String?,
      resolvedAt: json['resolved_at'] as String?,
      resolvedBy: json['resolved_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt,
        'user_id': userId,
        'title': title,
        'description': description,
        'severity': severity,
        'status': status,
        'page_path': pagePath,
        'user_agent': userAgent,
        'app_version': appVersion,
        'resolved_at': resolvedAt,
        'resolved_by': resolvedBy,
      };
}
