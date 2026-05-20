import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class AdminBroadcastDialog extends ConsumerStatefulWidget {
  const AdminBroadcastDialog({super.key});

  @override
  ConsumerState<AdminBroadcastDialog> createState() => _AdminBroadcastDialogState();
}

class _AdminBroadcastDialogState extends ConsumerState<AdminBroadcastDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _selectedType = 'info';
  String _selectedPriority = 'normal';
  bool _isBroadcast = true;
  int? _selectedTargetUserId;
  bool _isSubmitting = false;

  final List<String> _types = ['info', 'warning', 'success', 'error', 'system'];
  final List<String> _priorities = ['low', 'normal', 'high'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userProvider.notifier).fetchUsers();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_isBroadcast && _selectedTargetUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target user')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiService = ApiService();
      await apiService.sendAdminBroadcast(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        type: _selectedType,
        priority: _selectedPriority,
        targetUserId: _isBroadcast ? null : _selectedTargetUserId,
        isBroadcast: _isBroadcast,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return AlertDialog(
      title: const Text('Send Notification'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. System Maintenance',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Notification description...',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _types.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: _priorities.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPriority = val);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Broadcast to All Users'),
                value: _isBroadcast,
                onChanged: (val) {
                  setState(() => _isBroadcast = val);
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (!_isBroadcast) ...[
                const SizedBox(height: 12),
                if (userState.isLoading)
                  const CircularProgressIndicator()
                else if (userState.error != null)
                  Text('Error loading users: ${userState.error}', style: const TextStyle(color: Colors.red))
                else
                  DropdownButtonFormField<int>(
                    value: _selectedTargetUserId,
                    decoration: const InputDecoration(labelText: 'Select Target User'),
                    items: userState.users.map((user) {
                      return DropdownMenuItem(
                        value: user.id,
                        child: Text('${user.name} (${user.role.name})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedTargetUserId = val);
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Send'),
        ),
      ],
    );
  }
}
