import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transfer.dart';
import '../providers/transfer_provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/currency_converter.dart';
import '../providers/wallet_provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../widgets/project_selector.dart';

class AddTransferDialog extends ConsumerStatefulWidget {
  const AddTransferDialog({super.key});

  @override
  ConsumerState<AddTransferDialog> createState() => _AddTransferDialogState();
}

class _AddTransferDialogState extends ConsumerState<AddTransferDialog> {
  static int? _lastUsedProjectId;

  final _formKey = GlobalKey<FormState>();
  final _amountFromController = TextEditingController();
  final _amountToController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _selectedCurrencyFrom = 'USD';
  String _selectedCurrencyTo = 'TZS';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isAutoCalculating = true;
  int? _selectedWalletFromId;
  int? _selectedWalletToId;
  int? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = _lastUsedProjectId;
    _amountFromController.addListener(_onAmountFromChanged);
    Future.microtask(() {
      ref.read(walletProvider.notifier).fetchWallets().then((_) {
        final wallets = ref.read(walletProvider).wallets;
        final matchingFrom = wallets.where((w) => w.currency == _selectedCurrencyFrom).toList();
        final matchingTo = wallets.where((w) => w.currency == _selectedCurrencyTo).toList();
        setState(() {
          if (matchingFrom.isNotEmpty) _selectedWalletFromId = matchingFrom.first.id;
          if (matchingTo.isNotEmpty) _selectedWalletToId = matchingTo.first.id;
        });
      });
    });
  }

  @override
  void dispose() {
    _amountFromController.removeListener(_onAmountFromChanged);
    _amountFromController.dispose();
    _amountToController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onAmountFromChanged() {
    if (!_isAutoCalculating) return;
    final amountFrom = double.tryParse(_amountFromController.text);
    if (amountFrom == null || amountFrom <= 0) {
      _amountToController.text = '';
      return;
    }

    final rateFrom = CurrencyConverter.ratesToUsd[_selectedCurrencyFrom] ?? 1.0;
    final rateTo = CurrencyConverter.ratesToUsd[_selectedCurrencyTo] ?? 1.0;

    // Convert AmountFrom to USD, then to AmountTo
    // AmountTo = AmountFrom * (RateTo / RateFrom)
    final amountTo = amountFrom * (rateTo / rateFrom);
    _amountToController.text = amountTo.toStringAsFixed(2);
  }

  void _recalculate() {
    if (_isAutoCalculating) {
      _onAmountFromChanged();
    }
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

    final transfer = Transfer(
      amountFrom: double.parse(_amountFromController.text),
      currencyFrom: _selectedCurrencyFrom,
      amountTo: double.parse(_amountToController.text),
      currencyTo: _selectedCurrencyTo,
      date: _selectedDate,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      walletFromId: _selectedWalletFromId,
      walletToId: _selectedWalletToId,
      projectId: _selectedProjectId,
      project: selectedProjectName,
    );

    try {
      await ref.read(transferProvider.notifier).addTransfer(transfer);
      // Refresh dashboard balance
      await ref.read(dashboardProvider.notifier).fetchDashboardData();
      
      if (mounted) {
        _lastUsedProjectId = _selectedProjectId;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer recorded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transfer: $e'), backgroundColor: AppTheme.errorColor),
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
      title: const Text('New Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Source Wallet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountFromController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Send Amount',
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
                      value: _selectedCurrencyFrom,
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
                          _selectedCurrencyFrom = val!;
                          _recalculate();
                          final matching = ref.read(walletProvider).wallets
                              .where((w) => w.currency == _selectedCurrencyFrom)
                              .toList();
                          if (matching.isNotEmpty) {
                            _selectedWalletFromId = matching.first.id;
                          } else {
                            _selectedWalletFromId = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final walletsState = ref.watch(walletProvider);
                  final filteredWallets = walletsState.wallets
                      .where((w) => w.currency == _selectedCurrencyFrom)
                      .toList();
                  
                  return DropdownButtonFormField<int?>(
                    value: _selectedWalletFromId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Source Account / Wallet',
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
                    onChanged: (val) => setState(() => _selectedWalletFromId = val),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text('Destination Wallet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountToController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) {
                        setState(() {
                          _isAutoCalculating = false;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Receive Amount',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: !_isAutoCalculating
                          ? IconButton(
                              icon: const Icon(Icons.autorenew, size: 18),
                              onPressed: () {
                                setState(() {
                                  _isAutoCalculating = true;
                                  _recalculate();
                                });
                              },
                              tooltip: 'Auto calculate',
                            )
                          : null,
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
                      value: _selectedCurrencyTo,
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
                          _selectedCurrencyTo = val!;
                          _recalculate();
                          final matching = ref.read(walletProvider).wallets
                              .where((w) => w.currency == _selectedCurrencyTo)
                              .toList();
                          if (matching.isNotEmpty) {
                            _selectedWalletToId = matching.first.id;
                          } else {
                            _selectedWalletToId = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final walletsState = ref.watch(walletProvider);
                  final filteredWallets = walletsState.wallets
                      .where((w) => w.currency == _selectedCurrencyTo)
                      .toList();
                  
                  return DropdownButtonFormField<int?>(
                    value: _selectedWalletToId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Destination Account / Wallet',
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
                    onChanged: (val) => setState(() => _selectedWalletToId = val),
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
