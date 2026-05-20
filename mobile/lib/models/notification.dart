class AppNotification {
  final int id; // The user_notification link ID
  final int notificationId;
  final String title;
  final String message;
  final String type;
  final String priority;
  final bool isBroadcast;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.notificationId,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.isBroadcast,
    required this.createdAt,
    required this.isRead,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final notificationJson = json['notification'] as Map<String, dynamic>;
    return AppNotification(
      id: json['id'] as int,
      notificationId: notificationJson['id'] as int,
      title: notificationJson['title'] as String,
      message: notificationJson['message'] as String,
      type: notificationJson['type'] as String,
      priority: notificationJson['priority'] as String,
      isBroadcast: notificationJson['is_broadcast'] as bool,
      createdAt: DateTime.parse(notificationJson['created_at'] as String),
      isRead: json['is_read'] as bool,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
    );
  }
}
