import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';

class ProjectSelector extends ConsumerStatefulWidget {
  final int? selectedProjectId;
  final ValueChanged<Project?> onSelected;

  const ProjectSelector({
    super.key,
    required this.selectedProjectId,
    required this.onSelected,
  });

  @override
  ConsumerState<ProjectSelector> createState() => _ProjectSelectorState();
}

class _ProjectSelectorState extends ConsumerState<ProjectSelector> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(projectProvider.notifier).fetchProjects();
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
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return ProjectSelectionSheet(
              scrollController: scrollController,
              selectedProjectId: widget.selectedProjectId,
              onSelected: widget.onSelected,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectProvider);
    final selectedProject = projectsState.projects.firstWhere(
      (p) => p.id == widget.selectedProjectId,
      orElse: () => const Project(id: -1, name: 'No Project'),
    );

    final hasSelection = widget.selectedProjectId != null && selectedProject.id != -1;

    return InkWell(
      onTap: () => _showSelectorBottomSheet(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Project (Optional)',
          prefixIcon: Icon(
            hasSelection ? Icons.business_center : Icons.business_center_outlined,
            color: hasSelection ? AppTheme.primaryColor : Colors.grey,
          ),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(
          hasSelection ? selectedProject.name : 'Select Existing Project',
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

class ProjectSelectionSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final int? selectedProjectId;
  final ValueChanged<Project?> onSelected;

  const ProjectSelectionSheet({
    super.key,
    required this.scrollController,
    required this.selectedProjectId,
    required this.onSelected,
  });

  @override
  ConsumerState<ProjectSelectionSheet> createState() => _ProjectSelectionSheetState();
}

class _ProjectSelectionSheetState extends ConsumerState<ProjectSelectionSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _createNewProject(BuildContext context) {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) => const CreateProjectDialog(),
    ).then((newProj) {
      if (newProj != null && newProj is Project && mounted) {
        widget.onSelected(newProj);
        navigator.pop(); // Close bottom sheet
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectProvider);
    
    // Filter to active and upcoming projects in dropdown
    final activeProjects = projectsState.activeProjects.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Project',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              TextButton.icon(
                onPressed: () => _createNewProject(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Project', style: TextStyle(fontWeight: FontWeight.bold)),
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
              hintText: 'Search active projects...',
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

        // Project List
        Expanded(
          child: projectsState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : activeProjects.isEmpty && _searchQuery.isNotEmpty
                  ? const Center(child: Text('No active projects found.'))
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: activeProjects.length + 1, // +1 for "No Project"
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // No Project Option
                          final isSelected = widget.selectedProjectId == null;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child: const Icon(Icons.block, color: Colors.grey, size: 18),
                            ),
                            title: const Text(
                              'No Project (Skip)',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: const Text('Small office tea expense, generic transactions, etc.'),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
                            onTap: () {
                              widget.onSelected(null);
                              Navigator.pop(context);
                            },
                          );
                        }

                        final project = activeProjects[index - 1];
                        final isSelected = widget.selectedProjectId == project.id;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.business_center, color: AppTheme.primaryColor, size: 18),
                          ),
                          title: Text(
                            project.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            project.description ?? 'No description',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                              : Text(
                                  project.budget != null ? '${project.budget!.toStringAsFixed(0)} ${project.currency}' : 'No Budget',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                          onTap: () {
                            widget.onSelected(project);
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

class CreateProjectDialog extends ConsumerStatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  ConsumerState<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  
  String _selectedCurrency = 'USD';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final project = Project(
      name: _nameController.text.trim(),
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      budget: _budgetController.text.isNotEmpty ? double.tryParse(_budgetController.text) : null,
      currency: _selectedCurrency,
    );

    try {
      final newProj = await ref.read(projectProvider.notifier).addProject(project);
      if (mounted) {
        Navigator.pop(context, newProj);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project "${newProj.name}" created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating project: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Project', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  hintText: 'e.g. Tanzania Health Summit',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Project name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g. Conference attendance and logistics',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Budget (Optional)',
                        hintText: '0.00',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null || double.parse(value) < 0) {
                            return 'Enter positive number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'TZS', child: Text('TZS')),
                        DropdownMenuItem(value: 'KES', child: Text('KES')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCurrency = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('CREATE'),
        ),
      ],
    );
  }
}
