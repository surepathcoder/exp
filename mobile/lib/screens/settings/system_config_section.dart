import 'package:flutter/material.dart';
import '../../models/system_settings.dart';
import '../../theme/app_theme.dart';

class SystemConfigSection extends StatefulWidget {
  final SystemSettings settings;
  final bool isSaving;
  final Function(Map<String, dynamic>) onSave;
  final bool readOnly;

  const SystemConfigSection({
    super.key,
    required this.settings,
    required this.isSaving,
    required this.onSave,
    this.readOnly = false,
  });

  @override
  State<SystemConfigSection> createState() => _SystemConfigSectionState();
}

class _SystemConfigSectionState extends State<SystemConfigSection> {
  late TextEditingController _appNameCtrl;
  late TextEditingController _tzsRateCtrl;
  late TextEditingController _kesRateCtrl;
  late String _currency;
  late bool _useLiveRates;

  @override
  void initState() {
    super.initState();
    _appNameCtrl = TextEditingController(text: widget.settings.appName);
    _tzsRateCtrl = TextEditingController(text: widget.settings.manualRates?['USD_TZS']?.toString() ?? '2500.0');
    _kesRateCtrl = TextEditingController(text: widget.settings.manualRates?['USD_KES']?.toString() ?? '130.0');
    _currency = widget.settings.defaultCurrency;
    _useLiveRates = widget.settings.useLiveRates;
  }

  @override
  void dispose() {
    _appNameCtrl.dispose();
    _tzsRateCtrl.dispose();
    _kesRateCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave({
      'app_name': _appNameCtrl.text.trim(),
      'default_currency': _currency,
      'use_live_rates': _useLiveRates,
      'manual_rates': {
        'USD_TZS': double.tryParse(_tzsRateCtrl.text) ?? 2500.0,
        'USD_KES': double.tryParse(_kesRateCtrl.text) ?? 130.0,
      },
      'version': widget.settings.version,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _appNameCtrl,
          enabled: !widget.readOnly,
          decoration: const InputDecoration(labelText: 'App Name'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _currency,
          decoration: const InputDecoration(labelText: 'Default Currency'),
          items: const [
            DropdownMenuItem(value: 'USD', child: Text('USD')),
            DropdownMenuItem(value: 'TZS', child: Text('TZS')),
            DropdownMenuItem(value: 'KES', child: Text('KES')),
          ],
          onChanged: widget.readOnly ? null : (v) => setState(() => _currency = v ?? 'USD'),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Use Live Exchange Rates'),
          subtitle: Text(_useLiveRates ? 'Fetching from API' : 'Using manual rates'),
          value: _useLiveRates,
          activeColor: AppTheme.primaryColor,
          onChanged: widget.readOnly ? null : (v) => setState(() => _useLiveRates = v),
          contentPadding: EdgeInsets.zero,
        ),
        if (!_useLiveRates) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tzsRateCtrl,
                  enabled: !widget.readOnly,
                  decoration: const InputDecoration(labelText: 'USD → TZS Rate'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _kesRateCtrl,
                  enabled: !widget.readOnly,
                  decoration: const InputDecoration(labelText: 'USD → KES Rate'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
        if (!widget.readOnly) ...[
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: widget.isSaving ? null : _save,
            child: widget.isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Changes'),
          ),
        ],
      ],
    );
  }
}
