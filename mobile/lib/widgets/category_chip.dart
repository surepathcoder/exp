import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const CategoryChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final chipBgColor = color ?? AppTheme.primaryColor;
    final contentColor = isSelected
        ? (chipBgColor.computeLuminance() < 0.5 ? Colors.white : Colors.black87)
        : Colors.black87;

    return FilterChip(
      avatar: icon != null
          ? Icon(
              icon,
              color: isSelected ? contentColor : (color ?? Colors.grey.shade600),
              size: 14,
            )
          : null,
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: chipBgColor,
      labelStyle: TextStyle(
        color: contentColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      checkmarkColor: contentColor,
      showCheckmark: false, // Hide checkmark to let the custom icon shine
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? chipBgColor : Colors.grey.shade300,
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
