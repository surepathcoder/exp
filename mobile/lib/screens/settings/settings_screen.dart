import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/system_settings.dart';
import '../../widgets/settings/settings_section_card.dart';
import '../../widgets/loading_widget.dart';
import '../../theme/app_theme.dart';
import 'system_config_section.dart';
import 'category_section.dart';
import 'user_management_section.dart';
import 'security_section.dart';
import 'notification_section.dart';
import 'system_stats_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final Set<int> _expanded = {0};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(settingsProvider.notifier).fetchSettings());
  }

  void _toggle(int index) {
    setState(() {
      if (_expanded.contains(index)) {
        _expanded.remove(index);
      } else {
        _expanded.add(index);
      }
    });
  }

  Future<void> _saveSettings(Map<String, dynamic> data) async {
    final ok = await ref.read(settingsProvider.notifier).updateSettings(data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Settings saved' : 'Failed to save settings'),
        backgroundColor: ok ? Colors.green : AppTheme.errorColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);
    final user = ref.watch(authProvider).user;
    final isSuperAdmin = user?.role.name == 'superadmin';
    final isAdmin = user?.role.name == 'admin';
    final isAdminOrSuperAdmin = isSuperAdmin || isAdmin;

    ref.listen(settingsProvider, (prev, next) {
      if (next.error != null && (prev == null || prev.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppTheme.errorColor,
        ));
      }
    });

    if (state.isLoading && state.settings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const LoadingWidget(),
      );
    }

    final settings = state.settings ?? SystemSettings.defaults();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(settingsProvider.notifier).fetchSettings(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(settingsProvider.notifier).fetchSettings(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (isAdminOrSuperAdmin) ...[
                _buildSection(0, Icons.settings, 'System Configuration',
                  SystemConfigSection(settings: settings, isSaving: state.isSaving, onSave: _saveSettings, readOnly: !isSuperAdmin)),
                _buildSection(1, Icons.category, 'Category Management', CategorySection(isSuperAdmin: isSuperAdmin)),
                _buildSection(2, Icons.people, 'User Management', UserManagementSection(isSuperAdmin: isSuperAdmin)),
              ],
              _buildSection(3, Icons.lock, 'Security',
                SecuritySection(settings: settings, isSaving: state.isSaving, onSaveTimeout: isSuperAdmin ? _saveSettings : (_) {})),
              if (isSuperAdmin)
                _buildSection(4, Icons.notifications, 'Notification Defaults',
                  NotificationSection(settings: settings, isSaving: state.isSaving, onSave: _saveSettings)),
              if (isAdminOrSuperAdmin)
                _buildSection(5, Icons.analytics, 'System Stats', SystemStatsSection(isSuperAdmin: isSuperAdmin)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(int index, IconData icon, String title, Widget child) {
    return SettingsSectionCard(
      icon: icon,
      title: title,
      isExpanded: _expanded.contains(index),
      onToggle: () => _toggle(index),
      child: child,
    );
  }
}
