import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/wallet_provider.dart';
import 'wallet_card.dart';
import '../../theme/app_theme.dart';

class WalletList extends ConsumerWidget {
  const WalletList({super.key});

  void _showAddWalletDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AddWalletDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final textTheme = Theme.of(context).textTheme;

    if (walletState.isLoading && walletState.wallets.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Accounts & Wallets',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddWalletDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Account', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: walletState.wallets.length,
            itemBuilder: (context, index) {
              final wallet = walletState.wallets[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: WalletCard(
                  wallet: wallet,
                  onTap: () {
                    // Optional: filter dashboard/history by this wallet
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AddWalletDialog extends ConsumerStatefulWidget {
  const AddWalletDialog({super.key});

  @override
  ConsumerState<AddWalletDialog> createState() => _AddWalletDialogState();
}

class _AddWalletDialogState extends ConsumerState<AddWalletDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  
  String _selectedType = 'cash';
  String _selectedCurrency = 'USD';
  String _selectedColor = '#3D1B5B'; // Deep Purple
  String _selectedIcon = 'wallet';

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final success = await ref.read(walletProvider.notifier).createWallet(
      name: _nameController.text.trim(),
      type: _selectedType,
      currency: _selectedCurrency,
      openingBalance: balance,
      icon: _selectedIcon,
      color: _selectedColor,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet created successfully!'), backgroundColor: Colors.green),
        );
      } else {
        final error = ref.read(walletProvider).error ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $error'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Account / Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Account Name (e.g. M-Pesa, CRDB Bank)'),
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
                value: _selectedCurrency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD - US Dollar')),
                  DropdownMenuItem(value: 'TZS', child: Text('TZS - Tanzanian Shilling')),
                  DropdownMenuItem(value: 'KES', child: Text('KES - Kenyan Shilling')),
                ],
                onChanged: (val) => setState(() => _selectedCurrency = val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Opening Balance'),
                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid balance' : null,
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        TextButton(onPressed: _submit, child: const Text('CREATE')),
      ],
    );
  }
}
