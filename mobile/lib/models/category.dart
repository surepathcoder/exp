class AppCategory {
  final int id;
  final String name;
  final String color;
  final String? icon;
  final String type;
  final bool isActive;
  final int sortOrder;
  final String? createdAt;
  final String? updatedAt;

  const AppCategory({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    required this.type,
    required this.isActive,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    return AppCategory(
      id: json['id'],
      name: json['name'],
      color: json['color'] ?? '#9E9E9E',
      icon: json['icon'],
      type: json['type'] ?? 'expense',
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'icon': icon,
      'type': type,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}
