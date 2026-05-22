import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../widgets/navigation_drawer.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(userProvider.notifier).fetchUsers());
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final currentUser = ref.watch(authProvider).user;
    final isSuperAdmin = currentUser?.role.name == 'superadmin';
    final isAdmin = currentUser?.role.name == 'admin';
    final isAdminOrSuperAdmin = isSuperAdmin || isAdmin;

    ref.listen(userProvider, (previous, next) {
      if (next.error != null && (previous == null || previous.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppTheme.errorColor),
        );
      }
    });

    return Scaffold(
      drawer: MediaQuery.of(context).size.width < 600 ? const AppNavigationDrawer() : null,
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(userProvider.notifier).fetchUsers(),
          )
        ],
      ),
      body: userState.isLoading && userState.users.isEmpty
          ? const LoadingWidget()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userState.users.length,
              itemBuilder: (context, index) {
                final user = userState.users[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                       backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(user.email),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: user.role.name == 'superadmin' 
                                    ? AppTheme.secondaryColor.withOpacity(0.2)
                                    : user.role.name == 'admin'
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user.role.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: user.role.name == 'superadmin' 
                                      ? AppTheme.secondaryColor
                                      : user.role.name == 'admin'
                                          ? Colors.blue[700]
                                          : Colors.grey[700],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: user.isApproved
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user.isApproved ? 'APPROVED' : 'PENDING APPROVAL',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: user.isApproved ? Colors.green[700] : Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: isAdminOrSuperAdmin && currentUser?.id != user.id
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!user.isApproved)
                                TextButton.icon(
                                  icon: const Icon(Icons.check, color: Colors.green, size: 18),
                                  label: const Text('Approve', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    ref.read(userProvider.notifier).updateUserApproval(user.id, true);
                                  },
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.block, color: Colors.orange, size: 20),
                                  tooltip: 'Suspend Account',
                                  onPressed: () {
                                    ref.read(userProvider.notifier).updateUserApproval(user.id, false);
                                  },
                                ),
                              if (isSuperAdmin) ...[
                                const SizedBox(width: 8),
                                DropdownButton<String>(
                                  value: user.role.name,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(value: 'user', child: Text('User')),
                                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                    DropdownMenuItem(value: 'superadmin', child: Text('SuperAdmin')),
                                  ],
                                  onChanged: (newRole) {
                                    if (newRole != null) {
                                      ref.read(userProvider.notifier).updateUserRole(user.id, newRole);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete User'),
                                        content: Text('Are you sure you want to delete ${user.name}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(),
                                            child: const Text('CANCEL'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              ref.read(userProvider.notifier).deleteUser(user.id);
                                              Navigator.of(ctx).pop();
                                            },
                                            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
