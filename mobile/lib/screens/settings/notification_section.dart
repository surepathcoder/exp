import 'package:flutter/material.dart';
import '../../models/system_settings.dart';
import '../../theme/app_theme.dart';

class NotificationSection extends StatefulWidget {
  final SystemSettings settings;
  final bool isSaving;
  final Function(Map<String, dynamic>) onSave;

  const NotificationSection({
    super.key,
    required this.settings,
    required this.isSaving,
    required this.onSave,
  });

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection> {
  late String _type;
  late String _priority;

  @override
  void initState() {
    super.initState();
    _type = widget.settings.notificationDefaults?['type'] ?? 'info';
    _priority = widget.settings.notificationDefaults?['priority'] ?? 'normal';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _type,
          decoration: const InputDecoration(labelText: 'Default Type'),
          items: const [
            DropdownMenuItem(value: 'info', child: Text('Info')),
            DropdownMenuItem(value: 'warning', child: Text('Warning')),
            DropdownMenuItem(value: 'success', child: Text('Success')),
            DropdownMenuItem(value: 'error', child: Text('Error')),
            DropdownMenuItem(value: 'system', child: Text('System')),
          ],
          onChanged: (v) => setState(() => _type = v ?? 'info'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _priority,
          decoration: const InputDecoration(labelText: 'Default Priority'),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Low')),
            DropdownMenuItem(value: 'normal', child: Text('Normal')),
            DropdownMenuItem(value: 'high', child: Text('High')),
          ],
          onChanged: (v) => setState(() => _priority = v ?? 'normal'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: widget.isSaving ? null : () {
            widget.onSave({
              'notification_defaults': {
                'type': _type,
                'priority': _priority,
              },
              'version': widget.settings.version,
            });
          },
          child: widget.isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
