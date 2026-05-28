import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/category_provider.dart';
import '../../widgets/settings/category_tile.dart';
import '../../theme/app_theme.dart';
import '../../models/category.dart';
import '../../utils/category_icons.dart';
import '../../utils/color_parser.dart';

class CategorySection extends ConsumerStatefulWidget {
  final bool isSuperAdmin;
  const CategorySection({super.key, this.isSuperAdmin = true});

  @override
  ConsumerState<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends ConsumerState<CategorySection> {
  String _selectedType = 'expense';
  static const _protectedCategories = {'Other', 'Uncategorized', 'Salary', 'Transfer'};

  // Predefined elegant color palette
  static const List<String> _paletteColors = [
    '#3F51B5', // Indigo (Travel)
    '#FF9800', // Orange (Food)
    '#E91E63', // Pink (Worship/Hospitality)
    '#4CAF50', // Green (Invasion/Donations)
    '#00BCD4', // Cyan (Accommodation)
    '#9C27B0', // Purple (Volunteers)
    '#FF5722', // Deep Orange (Food & Drinks)
    '#009688', // Teal (Salary/Protocol)
    '#673AB7', // Deep Purple (Technical)
    '#FFC107', // Amber (Youth)
    '#607D8B', // Blue Grey (Transfer)
    '#9E9E9E', // Grey (Other/Promo)
  ];

  // Predefined popular icons
  static const List<String> _availableIcons = [
    'flight',
    'restaurant',
    'hotel',
    'directions_car',
    'shopping_cart',
    'local_cafe',
    'payments',
    'volunteer_activism',
    'school',
    'medical_services',
    'computer',
    'church',
    'groups',
    'work',
    'card_giftcard',
    'more_horiz',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(categoryProvider.notifier).fetchCategories(all: widget.isSuperAdmin));
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    String selectedColor = _paletteColors.first;
    String selectedIcon = _availableIcons.first;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDuplicateColor = ref.read(categoryProvider).categories.any(
                (c) => c.color.toUpperCase() == selectedColor.toUpperCase() && c.isActive,
              );

          return AlertDialog(
            title: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Live Preview
                    _buildPreviewCard(nameCtrl.text.trim(), selectedColor, selectedIcon),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'Enter name (e.g. Shopping)',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                      onChanged: (val) => setDlgState(() {}),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Icon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    _buildIconPicker(selectedIcon, (ico) => setDlgState(() => selectedIcon = ico)),
                    const SizedBox(height: 16),
                    const Text('Select Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    _buildColorPicker(
                      selectedColor,
                      (col) => setDlgState(() => selectedColor = col),
                      customController: null,
                    ),
                    if (isDuplicateColor) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '⚠️ This color is already used by an active category.',
                        style: TextStyle(color: Colors.orange, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final cats = ref.read(categoryProvider).categories;
                    final ok = await ref.read(categoryProvider.notifier).createCategory(
                          nameCtrl.text.trim(),
                          cats.length,
                          color: selectedColor,
                          icon: selectedIcon,
                          type: _selectedType,
                        );
                    if (ok && ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  }
                },
                child: const Text('ADD'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(AppCategory cat) {
    final nameCtrl = TextEditingController(text: cat.name);
    String selectedColor = cat.color;
    String selectedIcon = cat.icon ?? _availableIcons.last;
    final formKey = GlobalKey<FormState>();
    final isProtected = _protectedCategories.contains(cat.name);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDuplicateColor = ref.read(categoryProvider).categories.any(
                (c) => c.color.toUpperCase() == selectedColor.toUpperCase() && c.id != cat.id && c.isActive,
              );

          return AlertDialog(
            title: Text(isProtected ? 'Edit Category (System Default)' : 'Edit Category',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Live Preview
                    _buildPreviewCard(nameCtrl.text.trim(), selectedColor, selectedIcon),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      enabled: !isProtected,
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        helperText: isProtected ? 'System default category names cannot be changed' : null,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                      onChanged: (val) => setDlgState(() {}),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Icon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    _buildIconPicker(selectedIcon, (ico) => setDlgState(() => selectedIcon = ico)),
                    const SizedBox(height: 16),
                    const Text('Select Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    _buildColorPicker(
                      selectedColor,
                      (col) => setDlgState(() => selectedColor = col),
                      customController: null,
                    ),
                    if (isDuplicateColor) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '⚠️ This color is already used by another active category.',
                        style: TextStyle(color: Colors.orange, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final updateData = <String, dynamic>{
                      'color': selectedColor,
                      'icon': selectedIcon,
                    };
                    if (!isProtected) {
                      updateData['name'] = nameCtrl.text.trim();
                    }
                    final ok = await ref.read(categoryProvider.notifier).updateCategory(cat.id, updateData);
                    if (ok && ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  }
                },
                child: const Text('SAVE'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleDelete(AppCategory cat) {
    if (_protectedCategories.contains(cat.name)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cannot deactivate default category: ${cat.name}'),
        backgroundColor: AppTheme.errorColor,
      ));
      return;
    }

    if (cat.isActive) {
      ref.read(categoryProvider.notifier).deleteCategory(cat.id);
    } else {
      ref.read(categoryProvider.notifier).updateCategory(cat.id, {'is_active': true});
    }
  }

  // Previews the selected styling as a Category Chip
  Widget _buildPreviewCard(String name, String hexColor, String iconName) {
    final parsedColor = ColorParser.fromHex(hexColor);
    final iconData = CategoryIconHelper.getIcon(iconName);
    final contentColor = parsedColor.computeLuminance() < 0.5 ? Colors.white : Colors.black87;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            const Text('LIVE PREVIEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Chip(
              avatar: Icon(iconData, color: contentColor, size: 16),
              label: Text(
                name.isEmpty ? 'New Category' : name,
                style: TextStyle(color: contentColor, fontWeight: FontWeight.bold),
              ),
              backgroundColor: parsedColor,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconPicker(String selectedIcon, ValueChanged<String> onSelected) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _availableIcons.length,
        itemBuilder: (context, index) {
          final icoName = _availableIcons[index];
          final iconData = CategoryIconHelper.getIcon(icoName);
          final isSel = icoName == selectedIcon;

          return InkWell(
            onTap: () => onSelected(icoName),
            child: Container(
              decoration: BoxDecoration(
                color: isSel ? AppTheme.primaryColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                iconData,
                color: isSel ? Colors.white : Colors.black54,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorPicker(String selectedColor, ValueChanged<String> onSelected, {TextEditingController? customController}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Predefined grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _paletteColors.length,
          itemBuilder: (context, index) {
            final colHex = _paletteColors[index];
            final parsedCol = ColorParser.fromHex(colHex);
            final isSel = colHex.toLowerCase() == selectedColor.toLowerCase();

            return InkWell(
              onTap: () => onSelected(colHex),
              child: Container(
                decoration: BoxDecoration(
                  color: parsedCol,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSel ? Colors.black : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: isSel
                    ? Icon(
                        Icons.check,
                        color: parsedCol.computeLuminance() < 0.5 ? Colors.white : Colors.black,
                        size: 14,
                      )
                    : null,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Custom HEX Field
        Row(
          children: [
            const Text('Custom HEX: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: customController ?? TextEditingController(text: selectedColor),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                    hintText: '#AABBCC',
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (v) {
                    if (v.trim().startsWith('#') && (v.trim().length == 7 || v.trim().length == 9)) {
                      onSelected(v.trim());
                    } else if (!v.trim().startsWith('#') && (v.trim().length == 6 || v.trim().length == 8)) {
                      onSelected('#${v.trim()}');
                    }
                  },
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryProvider);

    if (state.isLoading && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredCategories = state.categories.where((c) => c.type == _selectedType).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab selector segmented button
        Center(
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'expense',
                label: Text('Expenses', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                icon: Icon(Icons.upload_sharp, size: 16),
              ),
              ButtonSegment(
                value: 'income',
                label: Text('Income', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                icon: Icon(Icons.download_sharp, size: 16),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (set) => setState(() => _selectedType = set.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.isSuperAdmin) ...[
          OutlinedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (filteredCategories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text('No categories found', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          )
        else
          // Reorderable or normal list representation
          widget.isSuperAdmin
              ? ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredCategories.length,
                  buildDefaultDragHandles: false, // Tile handles it manually
                  itemBuilder: (ctx, idx) {
                    final cat = filteredCategories[idx];
                    return CategoryTile(
                      key: ValueKey(cat.id),
                      category: cat,
                      index: idx,
                      isSuperAdmin: widget.isSuperAdmin,
                      onEdit: () => _showEditDialog(cat),
                      onDelete: () => _handleDelete(cat),
                    );
                  },
                  onReorder: (oldIdx, newIdx) async {
                    if (newIdx > oldIdx) newIdx -= 1;
                    final list = List<AppCategory>.from(filteredCategories);
                    final moved = list.removeAt(oldIdx);
                    list.insert(newIdx, moved);

                    final payload = list.asMap().entries.map((e) {
                      return {'id': e.value.id, 'sort_order': e.key};
                    }).toList();

                    // Trigger api reorder
                    await ref.read(categoryProvider.notifier).reorderCategories(payload);
                  },
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredCategories.length,
                  itemBuilder: (ctx, idx) {
                    final cat = filteredCategories[idx];
                    return CategoryTile(
                      key: ValueKey(cat.id),
                      category: cat,
                      index: idx,
                      isSuperAdmin: widget.isSuperAdmin,
                      onEdit: () {},
                      onDelete: () {},
                    );
                  },
                ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              state.error!,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
