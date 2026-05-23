import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reports_provider.dart';
import '../providers/category_provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/reports/reports_filter_form.dart';
import '../widgets/reports/reports_preview_panel.dart';
import '../widgets/navigation_drawer.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(categoryProvider.notifier).fetchCategories(all: false);
      final user = ref.read(authProvider).user;
      if (user != null && user.role.name != 'user') {
        ref.read(userProvider.notifier).fetchUsers();
      }
      ref.read(reportsProvider.notifier).fetchPreview();
    });
  }

  Future<void> _handleExport(String format) async {
    final success = await ref.read(reportsProvider.notifier).exportReport(format);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report exported successfully as ${format.toUpperCase()}!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      } else {
        final error = ref.read(reportsProvider).error ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;

    final exportButtons = Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: state.isExporting ? null : () => _handleExport('pdf'),
            icon: state.isExporting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf),
            label: const Text('Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: state.isExporting ? null : () => _handleExport('csv'),
            icon: state.isExporting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.table_chart),
            label: const Text('Export CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: isMobile ? const AppNavigationDrawer() : null,
      appBar: AppBar(
        title: const Text('Financial Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(reportsProvider.notifier).fetchPreview(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ReportsFilterForm(),
                  const SizedBox(height: 16),
                  exportButtons,
                  const SizedBox(height: 20),
                  const ReportsPreviewPanel(),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    flex: 4,
                    child: ReportsFilterForm(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        exportButtons,
                        const SizedBox(height: 20),
                        const ReportsPreviewPanel(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
