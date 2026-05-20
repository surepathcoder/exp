import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/category_provider.dart';
import '../../widgets/settings/category_tile.dart';
import '../../theme/app_theme.dart';

class CategorySection extends ConsumerStatefulWidget {
  const CategorySection({super.key});

  @override
  ConsumerState<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends ConsumerState<CategorySection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(categoryProvider.notifier).fetchCategories());
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final cats = ref.read(categoryProvider).categories;
              await ref.read(categoryProvider.notifier).createCategory(
                ctrl.text.trim(), cats.length,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int id, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref.read(categoryProvider.notifier).updateCategory(id, {'name': ctrl.text.trim()});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryProvider);

    if (state.isLoading && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Category'),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryColor),
        ),
        const SizedBox(height: 12),
        if (state.categories.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No categories found', textAlign: TextAlign.center),
          )
        else
          ...state.categories.map((cat) => CategoryTile(
            category: cat,
            onEdit: () => _showEditDialog(cat.id, cat.name),
            onDelete: () {
              if (cat.isActive) {
                ref.read(categoryProvider.notifier).deleteCategory(cat.id);
              } else {
                ref.read(categoryProvider.notifier).updateCategory(cat.id, {'is_active': true});
              }
            },
          )),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(state.error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 12)),
          ),
      ],
    );
  }
}
