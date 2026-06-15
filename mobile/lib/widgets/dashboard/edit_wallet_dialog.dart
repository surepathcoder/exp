import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wallet.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';

class EditWalletDialog extends ConsumerStatefulWidget {
  final Wallet wallet;
  const EditWalletDialog({super.key, required this.wallet});

  @override
  ConsumerState<EditWalletDialog> createState() => _EditWalletDialogState();
}

class _EditWalletDialogState extends ConsumerState<EditWalletDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  
  late String _selectedType;
  late String _selectedColor;
  late String _selectedIcon;

  final List<Map<String, String>> _colors = [
    {'name': 'Purple', 'hex': '#3D1B5B'},
    {'name': 'Orange', 'hex': '#FF5200'},
    {'name': 'Green', 'hex': '#10B981'},
    {'name': 'Blue', 'hex': '#3B82F6'},
    {'name': 'Red', 'hex': '#EF4444'},
  ];

  final List<Map<String, String>> _icons = [
    {'name': 'Wallet', 'val': 'wallet'},
    {'name': 'Bank', 'val': 'bank'},
    {'name': 'Phone', 'val': 'phone'},
    {'name': 'Card', 'val': 'card'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallet.name);
    
    // Safety check type
    final typeLower = widget.wallet.type.toLowerCase();
    if (['cash', 'bank', 'mobile_money', 'credit_card'].contains(typeLower)) {
      _selectedType = typeLower;
    } else {
      _selectedType = 'cash';
    }

    // Normalize and safety check color
    final matchingColor = _colors.any((c) => c['hex']!.toUpperCase() == widget.wallet.color.toUpperCase());
    if (matchingColor) {
      _selectedColor = _colors.firstWhere((c) => c['hex']!.toUpperCase() == widget.wallet.color.toUpperCase())['hex']!;
    } else {
      _colors.add({'name': 'Custom Color', 'hex': widget.wallet.color});
      _selectedColor = widget.wallet.color;
    }

    // Normalize and safety check icon
    final matchingIcon = _icons.any((i) => i['val']!.toLowerCase() == widget.wallet.icon.toLowerCase());
    if (matchingIcon) {
      _selectedIcon = _icons.firstWhere((i) => i['val']!.toLowerCase() == widget.wallet.icon.toLowerCase())['val']!;
    } else {
      _icons.add({'name': 'Custom Icon', 'val': widget.wallet.icon});
      _selectedIcon = widget.wallet.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(walletProvider.notifier).updateWallet(
      widget.wallet.id!,
      name: _nameController.text.trim(),
      type: _selectedType,
      color: _selectedColor,
      icon: _selectedIcon,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = ref.read(walletProvider).error ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete / Archive Account?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete or archive "${widget.wallet.name}"?\n\n'
          'If this account has transactions, it will be safely archived (hidden) rather than deleted to preserve your logs.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('DELETE / ARCHIVE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref.read(walletProvider.notifier).archiveWallet(widget.wallet.id!);
      if (mounted) {
        if (success) {
          Navigator.pop(context); // Close edit dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted/archived successfully.'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        } else {
          final error = ref.read(walletProvider).error ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $error'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Manage Account', style: TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
            onPressed: _delete,
            tooltip: 'Delete / Archive Account',
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Account Name'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Account Type'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Physical Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                  DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money')),
                  DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                ],
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedColor,
                decoration: const InputDecoration(labelText: 'Card Color'),
                items: _colors.map((c) => DropdownMenuItem(value: c['hex'], child: Text(c['name']!))).toList(),
                onChanged: (val) => setState(() => _selectedColor = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedIcon,
                decoration: const InputDecoration(labelText: 'Card Icon'),
                items: _icons.map((i) => DropdownMenuItem(value: i['val'], child: Text(i['name']!))).toList(),
                onChanged: (val) => setState(() => _selectedIcon = val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
