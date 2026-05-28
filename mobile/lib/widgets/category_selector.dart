import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';
import '../utils/category_icons.dart';
import '../utils/color_parser.dart';

class CategorySelector extends ConsumerStatefulWidget {
  final String selectedCategoryName;
  final ValueChanged<AppCategory> onSelected;

  const CategorySelector({
    super.key,
    required this.selectedCategoryName,
    required this.onSelected,
  });

  @override
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(categoryProvider.notifier).fetchCategories(all: false);
    });
  }

  void _showSelectorBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return CategorySelectionSheet(
              scrollController: scrollController,
              selectedCategoryName: widget.selectedCategoryName,
              onSelected: widget.onSelected,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final selectedCat = categoryState.categories.firstWhere(
      (c) => c.name == widget.selectedCategoryName,
      orElse: () => const AppCategory(id: -1, name: 'Select Category', color: '#9E9E9E', type: 'expense', isActive: true, sortOrder: 0),
    );

    final hasSelection = widget.selectedCategoryName.isNotEmpty && selectedCat.id != -1;
    final parsedColor = ColorParser.fromHex(selectedCat.color);
    final iconData = CategoryIconHelper.getIcon(selectedCat.icon);

    return InkWell(
      onTap: () => _showSelectorBottomSheet(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Category *',
          prefixIcon: Icon(
            hasSelection ? iconData : Icons.category_outlined,
            color: hasSelection ? parsedColor : Colors.grey,
          ),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(
          hasSelection ? selectedCat.name : 'Select Category',
          style: TextStyle(
            color: hasSelection ? Colors.black87 : Colors.grey[600],
            fontSize: 15,
            fontWeight: hasSelection ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class CategorySelectionSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final String selectedCategoryName;
  final ValueChanged<AppCategory> onSelected;

  const CategorySelectionSheet({
    super.key,
    required this.scrollController,
    required this.selectedCategoryName,
    required this.onSelected,
  });

  @override
  ConsumerState<CategorySelectionSheet> createState() => _CategorySelectionSheetState();
}

class _CategorySelectionSheetState extends ConsumerState<CategorySelectionSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    
    // Filter to active expense categories
    final expenseCats = categoryState.categories
        .where((c) => c.isActive && c.type == 'expense')
        .where((c) {
          if (_searchQuery.isEmpty) return true;
          return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

    return Column(
      children: [
        // Handle bar
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        
        // Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search categories...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),

        const Divider(height: 16),

        // Category List
        Expanded(
          child: categoryState.isLoading && expenseCats.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : expenseCats.isEmpty
                  ? const Center(child: Text('No expense categories found.'))
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: expenseCats.length,
                      itemBuilder: (context, index) {
                        final category = expenseCats[index];
                        final isSelected = widget.selectedCategoryName == category.name;
                        final parsedColor = ColorParser.fromHex(category.color);
                        final iconData = CategoryIconHelper.getIcon(category.icon);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: parsedColor.withOpacity(0.1),
                            child: Icon(iconData, color: parsedColor, size: 18),
                          ),
                          title: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: parsedColor)
                              : null,
                          onTap: () {
                            widget.onSelected(category);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
