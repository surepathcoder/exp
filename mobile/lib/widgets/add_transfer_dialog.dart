import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transfer.dart';
import '../providers/transfer_provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/currency_converter.dart';

class AddTransferDialog extends ConsumerStatefulWidget {
  const AddTransferDialog({super.key});

  @override
  ConsumerState<AddTransferDialog> createState() => _AddTransferDialogState();
}

class _AddTransferDialogState extends ConsumerState<AddTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountFromController = TextEditingController();
  final _amountToController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _selectedCurrencyFrom = 'USD';
  String _selectedCurrencyTo = 'TZS';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isAutoCalculating = true;

  @override
  void initState() {
    super.initState();
    _amountFromController.addListener(_onAmountFromChanged);
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

    final transfer = Transfer(
      amountFrom: double.parse(_amountFromController.text),
      currencyFrom: _selectedCurrencyFrom,
      amountTo: double.parse(_amountToController.text),
      currencyTo: _selectedCurrencyTo,
      date: _selectedDate,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    try {
      await ref.read(transferProvider.notifier).addTransfer(transfer);
      // Refresh dashboard balance
      await ref.read(dashboardProvider.notifier).fetchDashboardData();
      
      if (mounted) {
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
                        });
                      },
                    ),
                  ),
                ],
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
                        });
                      },
                    ),
                  ),
                ],
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
