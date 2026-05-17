import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/category_chip.dart';
import '../widgets/currency_picker.dart';
import '../theme/app_theme.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final int? expenseId;

  const AddExpenseScreen({super.key, this.expenseId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedCategory = Constants.categories.first;
  String _selectedCurrency = 'USD';
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isSelfReceipt = false;
  
  final _amountController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isEditing = false;
  Expense? _existingExpense;

  @override
  void initState() {
    super.initState();
    if (widget.expenseId != null) {
      _isEditing = true;
      Future.microtask(_loadExistingExpense);
    }
  }

  void _loadExistingExpense() {
    final expenses = ref.read(expenseProvider).expenses;
    final index = expenses.indexWhere((e) => e.id == widget.expenseId);
    if (index != -1) {
      setState(() {
        _existingExpense = expenses[index];
        _selectedCategory = _existingExpense!.category;
        _selectedCurrency = _existingExpense!.currency;
        _selectedPaymentMethod = _existingExpense!.paymentMethod ?? 'Cash';
        _selectedDate = _existingExpense!.date;
        _isSelfReceipt = _existingExpense!.isSelfReceipt;
        
        _amountController.text = _existingExpense!.amount.toString();
        _locationController.text = _existingExpense!.location ?? '';
        _noteController.text = _existingExpense!.note ?? '';
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        id: _existingExpense?.id,
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        category: _selectedCategory,
        date: _selectedDate,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        isSelfReceipt: _isSelfReceipt,
        paymentMethod: _selectedPaymentMethod,
        location: _locationController.text.isNotEmpty ? _locationController.text : null,
        userId: _existingExpense?.userId,
      );

      try {
        if (_isEditing) {
          await ref.read(expenseProvider.notifier).updateExpense(expense.id!, expense);
        } else {
          await ref.read(expenseProvider.notifier).addExpense(expense);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Expense updated' : 'Expense added')),
          );
          context.pop();
        }
      } catch (e) {
        // Error is handled by provider and shown in list view
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(expenseProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'New Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: 'Operations',
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Project',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                ),
                items: Constants.paymentMethods.map((String method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
              ),
              const SizedBox(height: 24),
              const Text(
                'Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: Constants.categories.map((category) {
                  return CategoryChip(
                    label: category,
                    isSelected: _selectedCategory == category,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                      ),
                      validator: Validators.amount,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: CurrencyPicker(
                      selectedCurrency: _selectedCurrency,
                      onChanged: (val) => setState(() => _selectedCurrency = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Is self receipt'),
                value: _isSelfReceipt,
                onChanged: (val) => setState(() => _isSelfReceipt = val!),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachButton(Icons.camera_alt, 'TAKE\nPHOTO'),
                  _buildAttachButton(Icons.image, 'PICK\nPHOTO'),
                  _buildAttachButton(Icons.picture_as_pdf, 'PICK\nPDF'),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _saveExpense,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('SAVE', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachButton(IconData icon, String label) {
    return Column(
      children: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Attachment mock UI')),
            );
          },
          icon: Icon(icon, size: 32, color: AppTheme.primaryColor),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
