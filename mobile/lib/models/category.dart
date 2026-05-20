class AppCategory {
  final int id;
  final String name;
  final bool isActive;
  final int sortOrder;
  final String? createdAt;
  final String? updatedAt;

  const AppCategory({
    required this.id,
    required this.name,
    required this.isActive,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    return AppCategory(
      id: json['id'],
      name: json['name'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sort_order': sortOrder,
    };
  }
}
