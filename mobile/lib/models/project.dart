import 'package:equatable/equatable.dart';

enum ProjectStatus {
  upcoming,
  active,
  completed,
  expired,
  cancelled
}

extension ProjectStatusExtension on ProjectStatus {
  String get name {
    switch (this) {
      case ProjectStatus.upcoming:
        return 'upcoming';
      case ProjectStatus.active:
        return 'active';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.expired:
        return 'expired';
      case ProjectStatus.cancelled:
        return 'cancelled';
    }
  }
}

ProjectStatus projectStatusFromString(String statusStr) {
  switch (statusStr.toLowerCase()) {
    case 'upcoming':
      return ProjectStatus.upcoming;
    case 'active':
      return ProjectStatus.active;
    case 'completed':
      return ProjectStatus.completed;
    case 'expired':
      return ProjectStatus.expired;
    case 'cancelled':
      return ProjectStatus.cancelled;
    default:
      return ProjectStatus.active;
  }
}

class Project extends Equatable {
  final int? id;
  final String name;
  final String? description;
  final double? budget;
  final String currency;
  final ProjectStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? userId;
  final DateTime? createdAt;

  const Project({
    this.id,
    required this.name,
    this.description,
    this.budget,
    this.currency = 'USD',
    this.status = ProjectStatus.active,
    this.startDate,
    this.endDate,
    this.userId,
    this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      budget: json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      currency: json['currency'] ?? 'USD',
      status: projectStatusFromString(json['status'] ?? 'active'),
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      userId: json['user_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'budget': budget,
      'currency': currency,
      'status': status.name,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Project copyWith({
    int? id,
    String? name,
    String? description,
    double? budget,
    String? currency,
    ProjectStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        budget,
        currency,
        status,
        startDate,
        endDate,
        userId,
        createdAt,
      ];
}
