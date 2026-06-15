import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/audit_provider.dart';
import '../models/enums.dart';
import '../models/audit_log.dart';
import '../models/user.dart';
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
    Future.microtask(() {
      ref.read(userProvider.notifier).fetchUsers();
      final currentUser = ref.read(authProvider).user;
      if (currentUser?.role.name == 'superadmin') {
        ref.read(auditProvider.notifier).fetchAuditLogs();
      }
    });
  }

  void _showAuditDetailsDialog(BuildContext context, AuditLog log) {
    String prettyPrintJson(String? rawJson) {
      if (rawJson == null || rawJson.trim().isEmpty) return 'None';
      try {
        final decoded = json.decode(rawJson);
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(decoded);
      } catch (e) {
        return rawJson;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Audit Log Details (ID: ${log.id})', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Actor Email', log.userEmail),
                _buildDetailRow('Action Done', log.action.toUpperCase()),
                _buildDetailRow('Target Entity', '${log.entityType} (ID: ${log.entityId ?? 'N/A'})'),
                _buildDetailRow('IP Address', log.ipAddress ?? 'N/A'),
                _buildDetailRow('Timestamp', DateFormat('MM/dd/yyyy hh:mm:ss a').format(log.createdAt)),
                const SizedBox(height: 12),
                const Text('Before Changes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    prettyPrintJson(log.beforeValue),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('After Changes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    prettyPrintJson(log.afterValue),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(UserState userState, bool isAdminOrSuperAdmin, User? currentUser) {
    if (userState.isLoading && userState.users.isEmpty) {
      return const LoadingWidget();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: userState.users.length,
      itemBuilder: (context, index) {
        final user = userState.users[index];
        final isSuperAdmin = currentUser?.role.name == 'superadmin';
        
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
    );
  }

  Widget _buildAuditLogsList(AuditState auditState) {
    if (auditState.isLoading && auditState.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (auditState.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 8),
            const Text('No audit logs recorded in the system.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: auditState.logs.length,
      itemBuilder: (context, index) {
        final log = auditState.logs[index];
        final timeStr = DateFormat('MM/dd/yy hh:mm a').format(log.createdAt);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(
              log.action.toLowerCase() == 'delete' 
                  ? Icons.delete_forever_outlined 
                  : log.action.toLowerCase() == 'update'
                      ? Icons.edit_note_outlined
                      : Icons.add_circle_outline,
              color: log.action.toLowerCase() == 'delete' 
                  ? AppTheme.errorColor 
                  : log.action.toLowerCase() == 'update'
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
            ),
            title: Text(
              '${log.action.toUpperCase()} ${log.entityType.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Actor: ${log.userEmail}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text('IP: ${log.ipAddress ?? "N/A"} | $timeStr', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () => _showAuditDetailsDialog(context, log),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final auditState = ref.watch(auditProvider);
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

    final body = isSuperAdmin
        ? TabBarView(
            children: [
              _buildUsersList(userState, isAdminOrSuperAdmin, currentUser),
              _buildAuditLogsList(auditState),
            ],
          )
        : _buildUsersList(userState, isAdminOrSuperAdmin, currentUser);

    final scaffold = Scaffold(
      drawer: MediaQuery.of(context).size.width < 600 ? const AppNavigationDrawer() : null,
      appBar: AppBar(
        title: Text(isSuperAdmin ? 'Admin Workspace' : 'Users', style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: isSuperAdmin
            ? const TabBar(
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.black54,
                tabs: [
                  Tab(icon: Icon(Icons.people), text: 'USERS'),
                  Tab(icon: Icon(Icons.history), text: 'AUDIT LOGS'),
                ],
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(userProvider.notifier).fetchUsers();
              if (isSuperAdmin) {
                ref.read(auditProvider.notifier).fetchAuditLogs();
              }
            },
          )
        ],
      ),
      body: body,
    );

    if (isSuperAdmin) {
      return DefaultTabController(
        length: 2,
        child: scaffold,
      );
    }
    return scaffold;
  }
}
