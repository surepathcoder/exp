import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../../services/settings_api_service.dart';
import '../../widgets/settings/create_user_dialog.dart';
import '../../theme/app_theme.dart';

class UserManagementSection extends ConsumerStatefulWidget {
  final bool isSuperAdmin;
  const UserManagementSection({super.key, this.isSuperAdmin = true});

  @override
  ConsumerState<UserManagementSection> createState() => _UserManagementSectionState();
}

class _UserManagementSectionState extends ConsumerState<UserManagementSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(userProvider.notifier).fetchUsers());
  }

  void _showResetPasswordDialog(int userId, String userName) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password — $userName'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'New Password'),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.length < 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Min 6 characters')),
                );
                return;
              }
              try {
                await ref.read(settingsApiProvider).resetPassword(userId, ctrl.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset successfully')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
                  );
                }
              }
            },
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.isSuperAdmin) ...[
          OutlinedButton.icon(
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (_) => const CreateUserDialog(),
              );
              if (result == true) {
                ref.read(userProvider.notifier).fetchUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User created successfully')),
                  );
                }
              }
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Create User'),
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryColor),
          ),
          const SizedBox(height: 12),
        ],
        if (state.isLoading && state.users.isEmpty)
          const Center(child: CircularProgressIndicator())
        else
          ...state.users.map((user) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor,
                child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(user.email, style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.role.name == 'superadmin'
                              ? AppTheme.secondaryColor.withOpacity(0.15)
                              : user.role.name == 'admin'
                                  ? Colors.blue.withOpacity(0.15)
                                  : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.role.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.isApproved
                              ? Colors.green.withOpacity(0.15)
                              : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.isApproved ? 'APPROVED' : 'PENDING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: user.isApproved ? Colors.green[700] : Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: widget.isSuperAdmin
                  ? IconButton(
                      icon: const Icon(Icons.lock_reset, size: 20),
                      tooltip: 'Reset Password',
                      onPressed: () => _showResetPasswordDialog(user.id, user.name),
                    )
                  : null,
            ),
          )),
      ],
    );
  }
}
