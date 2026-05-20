import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../theme/app_theme.dart';

class CategoryTile extends StatelessWidget {
  final AppCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryTile({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: category.isActive ? Colors.white : Colors.grey.shade100,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          Icons.drag_indicator,
          color: Colors.grey[400],
          size: 20,
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: category.isActive ? null : TextDecoration.lineThrough,
            color: category.isActive ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: !category.isActive
            ? const Text('Inactive', style: TextStyle(fontSize: 11, color: Colors.red))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              color: AppTheme.primaryColor,
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(
                category.isActive ? Icons.delete_outline : Icons.restore,
                size: 18,
              ),
              color: category.isActive ? AppTheme.errorColor : Colors.green,
              onPressed: onDelete,
              tooltip: category.isActive ? 'Deactivate' : 'Restore',
            ),
          ],
        ),
      ),
    );
  }
}
