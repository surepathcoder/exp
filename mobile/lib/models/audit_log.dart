class AuditLog {
  final int id;
  final int userId;
  final String userEmail;
  final String action;
  final String entityType;
  final String? entityId;
  final String? beforeValue;
  final String? afterValue;
  final String? ipAddress;
  final String createdAt;

  const AuditLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.action,
    required this.entityType,
    this.entityId,
    this.beforeValue,
    this.afterValue,
    this.ipAddress,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      userId: json['user_id'],
      userEmail: json['user_email'] ?? '',
      action: json['action'] ?? '',
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id'],
      beforeValue: json['before_value'],
      afterValue: json['after_value'],
      ipAddress: json['ip_address'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
