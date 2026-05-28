import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/reports_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icons.dart';

class ReportsFilterForm extends ConsumerWidget {
  const ReportsFilterForm({super.key});

  List<String> _getUniqueProjects(WidgetRef ref) {
    final projects = ref.watch(projectProvider).projects.map((p) => p.name).toList();
    if (projects.isEmpty) {
      return ['Operations', 'Missions', 'Worship Night', 'Youth Camp'].toList()..sort();
    }
    return projects..sort();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsProvider);
    final notifier = ref.read(reportsProvider.notifier);
    
    final categoryState = ref.watch(categoryProvider);
    final userState = ref.watch(userProvider);
    final currentUser = ref.watch(authProvider).user;
    final isAdmin = currentUser != null && currentUser.role.name != 'user';

    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report Filters', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 12),
            
            // Report Type Dropdown
            DropdownButtonFormField<String>(
              value: state.reportType,
              decoration: const InputDecoration(labelText: 'Report Type'),
              items: const [
                DropdownMenuItem(value: 'combined', child: Text('Combined Financial Report')),
                DropdownMenuItem(value: 'expenses', child: Text('Expenses Report')),
                DropdownMenuItem(value: 'incomes', child: Text('Incomes Report')),
                DropdownMenuItem(value: 'transfers', child: Text('Transfers Report')),
              ],
              onChanged: (val) {
                if (val != null) notifier.updateFilters(reportType: val);
              },
            ),
            const SizedBox(height: 12),

            // Date Range Selection
            InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: state.startDate != null && state.endDate != null
                      ? DateTimeRange(start: state.startDate!, end: state.endDate!)
                      : null,
                );
                if (picked != null) {
                  notifier.updateFilters(startDate: picked.start, endDate: picked.end);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date Range',
                  prefixIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.startDate == null
                          ? 'All Dates'
                          : '${DateFormat('yyyy-MM-dd').format(state.startDate!)} to ${DateFormat('yyyy-MM-dd').format(state.endDate!)}',
                    ),
                    if (state.startDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => notifier.updateFilters(clearDates: true),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Admin User Filter
            if (isAdmin) ...[
              DropdownButtonFormField<int?>(
                value: state.selectedUserId,
                decoration: const InputDecoration(labelText: 'Filter by User'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All Users')),
                  ...userState.users.map((u) => DropdownMenuItem<int?>(value: u.id, child: Text(u.name))),
                ],
                onChanged: (val) {
                  notifier.updateFilters(userId: val, clearUser: val == null);
                },
              ),
              const SizedBox(height: 12),
            ],

            // Categories Filter (Only relevant if showing expenses or combined)
            if (state.reportType == 'expenses' || state.reportType == 'combined') ...[
              Text('Categories', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: categoryState.categories.where((c) => c.type == 'expense').map((category) {
                  final isSelected = state.selectedCategories.contains(category.name);
                  return FilterChip(
                    avatar: Icon(CategoryIconHelper.getIcon(category.icon), size: 14, color: isSelected ? Colors.white : Colors.grey),
                    label: Text(category.name, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                    selected: isSelected,
                    onSelected: (selected) {
                      final list = List<String>.from(state.selectedCategories);
                      if (selected) {
                        list.add(category.name);
                      } else {
                        list.remove(category.name);
                      }
                      notifier.updateFilters(categories: list);
                    },
                    selectedColor: AppTheme.primaryColor,
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              
              Text('Projects', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _getUniqueProjects(ref).map((project) {
                  final isSelected = state.selectedProjects.contains(project);
                  return FilterChip(
                    label: Text(project, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                    selected: isSelected,
                    onSelected: (selected) {
                      final list = List<String>.from(state.selectedProjects);
                      if (selected) {
                        list.add(project);
                      } else {
                        list.remove(project);
                      }
                      notifier.updateFilters(projects: list);
                    },
                    selectedColor: AppTheme.primaryColor,
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
