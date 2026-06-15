import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'edit_project_dialog.dart';

class ProjectDetailsDialog extends ConsumerStatefulWidget {
  final Project project;
  const ProjectDetailsDialog({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailsDialog> createState() => _ProjectDetailsDialogState();
}

class _ProjectDetailsDialogState extends ConsumerState<ProjectDetailsDialog> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final summary = await ref.read(apiServiceProvider).getProjectSummary(widget.project.id!);
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editProject() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => EditProjectDialog(project: widget.project),
    );
    if (updated == true) {
      // Re-fetch project details and notify parent list
      _fetchSummary();
      ref.read(projectProvider.notifier).fetchProjects();
    }
  }

  Future<void> _deleteProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${widget.project.name}"?\n\n'
          'Note: You cannot delete a project if it has transactions linked to it. For projects with transactions, you should edit the status to COMPLETED or EXPIRED instead.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref.read(projectProvider.notifier).deleteProject(widget.project.id!);
      if (mounted) {
        if (success) {
          Navigator.pop(context, true); // Close details dialog and tell parent to refresh
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project deleted successfully!'), backgroundColor: Colors.green),
          );
        } else {
          final error = ref.read(projectProvider).error ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $error'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = widget.project.currency;
    final format = NumberFormat.currency(
      symbol: currency == 'USD' ? '\$' : '$currency ',
      decimalDigits: currency == 'USD' ? 2 : 0,
    );

    Widget content;
    if (_isLoading) {
      content = const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      content = SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 40),
              const SizedBox(height: 8),
              Text('Error loading summary: $_error', textAlign: TextAlign.center),
              TextButton(onPressed: _fetchSummary, child: const Text('Retry')),
            ],
          ),
        ),
      );
    } else {
      final s = _summary!;
      final budget = (s['budget'] as num?)?.toDouble() ?? 0.0;
      final totalExpenses = (s['total_expenses'] as num?)?.toDouble() ?? 0.0;
      final totalIncomes = (s['total_incomes'] as num?)?.toDouble() ?? 0.0;
      final balance = (s['remaining_balance'] as num?)?.toDouble() ?? 0.0;
      
      final double percentUsed = budget > 0 ? (totalExpenses / budget).clamp(0.0, 1.0) : 0.0;
      final double percentVal = budget > 0 ? (totalExpenses / budget) * 100 : 0.0;
      final isOverBudget = totalExpenses > budget && budget > 0;

      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.project.description != null && widget.project.description!.isNotEmpty) ...[
            Text(
              widget.project.description!,
              style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
          ],
          
          // Metrics Row
          Card(
            color: Colors.grey[50],
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricColumn('Budget', budget > 0 ? format.format(budget) : 'No Limit', Colors.black87),
                  _buildMetricColumn('Total Expenses', format.format(totalExpenses), isOverBudget ? AppTheme.errorColor : Colors.orange.shade800),
                  _buildMetricColumn('Remaining', format.format(balance), balance >= 0 ? Colors.green.shade700 : AppTheme.errorColor),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Inflow / Outflow Summary details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Project Income:', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
              Text(format.format(totalIncomes), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Project Expenses:', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
              Text(format.format(totalExpenses), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
            ],
          ),
          
          if (budget > 0) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Allocation Used: ${percentVal.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (isOverBudget)
                  const Text(
                    'OVER BUDGET!',
                    style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentUsed,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? AppTheme.errorColor : AppTheme.primaryColor,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          // Timeline Info
          if (widget.project.startDate != null || widget.project.endDate != null) ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.date_range, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Timeline: '
                  '${widget.project.startDate != null ? DateFormat('MM/dd/yyyy').format(widget.project.startDate!) : 'Start'} - '
                  '${widget.project.endDate != null ? DateFormat('MM/dd/yyyy').format(widget.project.endDate!) : 'End'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      );
    }

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.project.name, 
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.project.status.name.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
      content: content,
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              onPressed: _deleteProject,
              tooltip: 'Delete Project',
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
                ElevatedButton.icon(
                  onPressed: _editProject,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('EDIT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
