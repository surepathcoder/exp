import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../providers/income_provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../providers/wallet_provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../widgets/project_selector.dart';

class AddIncomeDialog extends ConsumerStatefulWidget {
  const AddIncomeDialog({super.key});

  @override
  ConsumerState<AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends ConsumerState<AddIncomeDialog> {
  static int? _lastUsedProjectId;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _selectedCurrency = 'USD';
  String _selectedSource = 'Salary';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  int? _selectedWalletId;
  int? _selectedProjectId;

  final List<String> _sources = ['Salary', 'Donation', 'Investment', 'Refund', 'Other'];

  @override
  void initState() {
    super.initState();
    _selectedProjectId = _lastUsedProjectId;
    Future.microtask(() {
      ref.read(walletProvider.notifier).fetchWallets().then((_) {
        final matching = ref.read(walletProvider).wallets
            .where((w) => w.currency == _selectedCurrency)
            .toList();
        if (matching.isNotEmpty) {
          setState(() {
            _selectedWalletId = matching.first.id;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final selectedProjectName = _selectedProjectId == null
        ? null
        : ref.read(projectProvider).projects.firstWhere(
            (p) => p.id == _selectedProjectId,
            orElse: () => const Project(id: -1, name: ''),
          ).name;

    final income = Income(
      amount: double.parse(_amountController.text),
      currency: _selectedCurrency,
      source: _selectedSource,
      date: _selectedDate,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      walletId: _selectedWalletId,
      projectId: _selectedProjectId,
      project: selectedProjectName,
    );

    try {
      await ref.read(incomeProvider.notifier).addIncome(income);
      // Refresh dashboard balance
      await ref.read(dashboardProvider.notifier).fetchDashboardData();
      
      if (mounted) {
        _lastUsedProjectId = _selectedProjectId;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding income: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Income', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Enter positive number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: Constants.currencies.map((curr) => DropdownMenuItem(
                        value: curr,
                        child: Text(curr),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCurrency = val!;
                          final matching = ref.read(walletProvider).wallets
                              .where((w) => w.currency == _selectedCurrency)
                              .toList();
                          if (matching.isNotEmpty) {
                            _selectedWalletId = matching.first.id;
                          } else {
                            _selectedWalletId = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final walletsState = ref.watch(walletProvider);
                  final filteredWallets = walletsState.wallets
                      .where((w) => w.currency == _selectedCurrency)
                      .toList();
                  
                  return DropdownButtonFormField<int?>(
                    value: _selectedWalletId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Deposit To Account / Wallet',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'No Account (Generic Balance)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...filteredWallets.map((w) => DropdownMenuItem<int?>(
                        value: w.id,
                        child: Text(
                          '${w.name} (${w.currency})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                    ],
                    onChanged: (val) => setState(() => _selectedWalletId = val),
                  );
                },
              ),
              const SizedBox(height: 16),
              ProjectSelector(
                selectedProjectId: _selectedProjectId,
                onSelected: (project) {
                  setState(() {
                    _selectedProjectId = project?.id;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSource,
                decoration: const InputDecoration(
                  labelText: 'Source',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _sources.map((src) => DropdownMenuItem(
                  value: src,
                  child: Text(src),
                )).toList(),
                onChanged: (val) => setState(() => _selectedSource = val!),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: _isLoading 
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('SAVE'),
        ),
      ],
    );
  }
}
