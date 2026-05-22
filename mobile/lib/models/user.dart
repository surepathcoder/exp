import 'package:equatable/equatable.dart';
import 'enums.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final bool isApproved;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isApproved,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: roleFromString(json['role']),
      isApproved: json['is_approved'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'is_approved': isApproved,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, email, role, isApproved, createdAt];
}
