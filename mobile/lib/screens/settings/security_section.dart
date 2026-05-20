import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../models/system_settings.dart';
import '../../theme/app_theme.dart';

class SecuritySection extends ConsumerStatefulWidget {
  final SystemSettings settings;
  final bool isSaving;
  final Function(Map<String, dynamic>) onSaveTimeout;

  const SecuritySection({
    super.key,
    required this.settings,
    required this.isSaving,
    required this.onSaveTimeout,
  });

  @override
  ConsumerState<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends ConsumerState<SecuritySection> {
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  late TextEditingController _timeoutCtrl;
  bool _changingPwd = false;
  String? _pwdError;
  String? _pwdSuccess;

  @override
  void initState() {
    super.initState();
    _timeoutCtrl = TextEditingController(
      text: widget.settings.sessionTimeoutMinutes.toString(),
    );
  }

  @override
  void dispose() {
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _timeoutCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
      setState(() => _pwdError = 'Passwords do not match');
      return;
    }
    if (_newPwdCtrl.text.length < 6) {
      setState(() => _pwdError = 'Min 6 characters');
      return;
    }
    setState(() { _changingPwd = true; _pwdError = null; _pwdSuccess = null; });
    final ok = await ref.read(settingsProvider.notifier).changePassword(
      _currentPwdCtrl.text, _newPwdCtrl.text,
    );
    setState(() {
      _changingPwd = false;
      if (ok) {
        _pwdSuccess = 'Password updated successfully';
        _currentPwdCtrl.clear();
        _newPwdCtrl.clear();
        _confirmPwdCtrl.clear();
      } else {
        _pwdError = ref.read(settingsProvider).error ?? 'Failed to change password';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 12),
        if (_pwdError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_pwdError!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
          ),
        if (_pwdSuccess != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_pwdSuccess!, style: const TextStyle(color: Colors.green, fontSize: 13)),
          ),
        TextField(controller: _currentPwdCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
        const SizedBox(height: 10),
        TextField(controller: _newPwdCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
        const SizedBox(height: 10),
        TextField(controller: _confirmPwdCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _changingPwd ? null : _changePassword,
          child: _changingPwd
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Update Password'),
        ),
        const Divider(height: 32),
        const Text('Session Timeout', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _timeoutCtrl,
                decoration: const InputDecoration(labelText: 'Timeout (minutes)', suffixText: 'min'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: widget.isSaving ? null : () {
                widget.onSaveTimeout({
                  'session_timeout_minutes': int.tryParse(_timeoutCtrl.text) ?? 1440,
                  'version': widget.settings.version,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
