import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/unread_notification_provider.dart';
import '../theme/app_theme.dart';

class AppNavigationDrawer extends ConsumerWidget {
  final bool isDrawer;
  const AppNavigationDrawer({super.key, this.isDrawer = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final showUsersTab = user != null && user.role.name != 'user';
    final location = GoRouterState.of(context).matchedLocation;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          // Drawer Header matching screenshot aesthetics
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 16,
              bottom: 16,
            ),
            color: AppTheme.primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Migori Liclused',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isDrawer)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context); // Close drawer
                    },
                  ),
              ],
            ),
          ),
          // Drawer Body List Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.info_outline,
                  label: 'ABOUT',
                  isSelected: false,
                  onTap: () {
                    if (isDrawer) Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'BALANCE',
                  isSelected: location.startsWith('/dashboard'),
                  onTap: () {
                    if (isDrawer) Navigator.pop(context);
                    context.go('/dashboard');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.receipt_long_outlined,
                  label: 'TRANSACTIONS',
                  isSelected: location.startsWith('/expenses'),
                  onTap: () {
                    if (isDrawer) Navigator.pop(context);
                    context.go('/expenses');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.assignment_outlined,
                  label: 'PROJECTS',
                  isSelected: location.startsWith('/projects'),
                  onTap: () {
                    if (isDrawer) Navigator.pop(context);
                    context.go('/projects');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.assessment_outlined,
                  label: 'REPORTS',
                  isSelected: location.startsWith('/reports'),
                  onTap: () {
                    if (isDrawer) Navigator.pop(context);
                    context.go('/reports');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.notifications_none_outlined,
                  label: 'ALERTS',
                  isSelected: location.startsWith('/notifications'),
                  badgeCount: ref.watch(unreadNotificationProvider),
                  onTap: () {
                    if (isDrawer) Navigator.pop(context);
                    context.go('/notifications');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  label: 'MY SETTINGS',
                  isSelected: location.startsWith('/profile') || location.startsWith('/settings') || location.startsWith('/change-password'),
                  onTap: () {
                    if (isDrawer) Navigator.pop(context);
                    context.go('/profile');
                  },
                ),
                if (showUsersTab)
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'ADMIN WORKSPACE',
                    isSelected: location.startsWith('/users'),
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      context.go('/users');
                    },
                  ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.help_outline,
                  label: 'HELP',
                  isSelected: false,
                  onTap: () {
                    if (isDrawer) Navigator.pop(context);
                    _showHelpDialog(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Logout list tile
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text(
              'LOGOUT',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              if (isDrawer) Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
          ),
          // Drawer Footer matching screenshot
          Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 8),
            child: Text(
              'v1.0.4 - Production DRC',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    const activeColor = AppTheme.primaryColor;
    const inactiveColor = Colors.black54;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : const Color.fromARGB(255, 30, 30, 30) == Colors.black ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (badgeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (isSelected)
              Container(
                width: 4,
                height: 52,
                color: activeColor,
              ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Migori Liclused'),
        content: const Text(
          'Migori Liclused is a production-ready expense tracker and financial management app '
          'designed for resource optimization and tracking in the Democratic Republic of the Congo and East Africa.\n\n'
          'Version: 1.0.4 - Production DRC',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For support or inquiries regarding Migori Liclused, please contact our system administration team or reach out to support@awoken.com.\n\n'
          'Our team is available 24/7 to resolve database synchronization or security configurations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
