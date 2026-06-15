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
  final DateTime createdAt;

  AuditLog({
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
      id: json['id'] as int,
      userId: json['user_id'] as int,
      userEmail: json['user_email'] as String,
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String?,
      beforeValue: json['before_value'] as String?,
      afterValue: json['after_value'] as String?,
      ipAddress: json['ip_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'before_value': beforeValue,
      'after_value': afterValue,
      'ip_address': ipAddress,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
