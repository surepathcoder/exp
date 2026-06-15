import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/navigation_drawer.dart';
import '../widgets/project_details_dialog.dart';
import '../widgets/edit_project_dialog.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String _searchText = '';
  String _selectedStatusFilter = 'ALL'; // 'ALL', 'ACTIVE', 'UPCOMING', 'COMPLETED', 'EXPIRED', 'CANCELLED'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(projectProvider.notifier).fetchProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddProjectDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const EditProjectDialog(),
    );
    if (created == true) {
      ref.read(projectProvider.notifier).fetchProjects();
    }
  }

  void _showProjectDetails(Project project) {
    showDialog(
      context: context,
      builder: (context) => ProjectDetailsDialog(project: project),
    ).then((_) {
      ref.read(projectProvider.notifier).fetchProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;

    // Filter projects locally by status & search
    final filteredProjects = state.projects.where((p) {
      // 1. Status Filter
      if (_selectedStatusFilter != 'ALL') {
        if (p.status.name.toUpperCase() != _selectedStatusFilter) {
          return false;
        }
      }
      
      // 2. Search Text Filter
      if (_searchText.isNotEmpty) {
        final nameMatch = p.name.toLowerCase().contains(_searchText.toLowerCase());
        final descMatch = p.description?.toLowerCase().contains(_searchText.toLowerCase()) ?? false;
        if (!nameMatch && !descMatch) return false;
      }
      
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: isMobile ? const AppNavigationDrawer() : null,
      appBar: AppBar(
        title: const Text('Project Portfolios', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(projectProvider.notifier).fetchProjects(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar Card
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search TextField
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchText.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchText = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchText = val.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Status Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['ALL', 'ACTIVE', 'UPCOMING', 'COMPLETED', 'EXPIRED', 'CANCELLED'].map((status) {
                        final isSelected = _selectedStatusFilter == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(status),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedStatusFilter = status;
                                });
                              }
                            },
                            selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                            checkmarkColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.primaryColor : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Projects List View
          Expanded(
            child: state.isLoading && state.projects.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredProjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No projects found matching filters',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(projectProvider.notifier).fetchProjects(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: filteredProjects.length,
                          itemBuilder: (context, index) {
                            final project = filteredProjects[index];
                            final currency = project.currency;
                            final format = NumberFormat.currency(
                              symbol: currency == 'USD' ? '\$' : '$currency ',
                              decimalDigits: currency == 'USD' ? 2 : 0,
                            );

                            // Get Status color indicator
                            Color statusColor = Colors.green;
                            if (project.status == ProjectStatus.upcoming) statusColor = Colors.blue;
                            if (project.status == ProjectStatus.completed) statusColor = Colors.grey;
                            if (project.status == ProjectStatus.expired) statusColor = Colors.orange;
                            if (project.status == ProjectStatus.cancelled) statusColor = AppTheme.errorColor;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              color: Colors.white,
                              child: InkWell(
                                onTap: () => _showProjectDetails(project),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              project.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              project.status.name.toUpperCase(),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (project.description != null && project.description!.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          project.description!,
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const Divider(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('BUDGET LIMIT', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                                              const SizedBox(height: 4),
                                              Text(
                                                project.budget != null 
                                                    ? format.format(project.budget) 
                                                    : 'No Limit Set',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ],
                                          ),
                                          if (project.startDate != null || project.endDate != null)
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text('TIMELINE', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${project.startDate != null ? DateFormat('MM/dd/yy').format(project.startDate!) : 'Start'} - '
                                                  '${project.endDate != null ? DateFormat('MM/dd/yy').format(project.endDate!) : 'End'}',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectDialog,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
