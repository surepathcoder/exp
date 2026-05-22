import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icons.dart';
import '../../utils/color_parser.dart';

class CategoryTile extends StatelessWidget {
  final AppCategory category;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryTile({
    super.key,
    required this.category,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final parsedColor = ColorParser.fromHex(category.color);
    final iconData = CategoryIconHelper.getIcon(category.icon);
    final contentColor = parsedColor.computeLuminance() < 0.5 ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        color: category.isActive ? Colors.white : Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_indicator,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: parsedColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: contentColor,
                size: 18,
              ),
            ),
          ],
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: category.isActive ? null : TextDecoration.lineThrough,
            color: category.isActive ? Colors.black87 : Colors.grey,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          category.isActive ? category.type.toUpperCase() : 'Inactive (${category.type.toUpperCase()})',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: !category.isActive
                ? Colors.red
                : (category.type == 'income' ? Colors.green : Colors.blueGrey),
          ),
        ),
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
