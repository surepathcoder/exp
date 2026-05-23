import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/category_chip.dart';
import '../widgets/currency_picker.dart';
import '../theme/app_theme.dart';
import '../providers/category_provider.dart';
import '../utils/color_parser.dart';
import '../utils/category_icons.dart';
import '../providers/wallet_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final int? expenseId;

  const AddExpenseScreen({super.key, this.expenseId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedCategory = '';
  String _selectedCurrency = 'USD';
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isSelfReceipt = false;
  int? _selectedWalletId;
  
  final _amountController = TextEditingController();
  final _locationController = TextEditingController();
  final _vendorController = TextEditingController();
  final _noteController = TextEditingController();
  final _projectController = TextEditingController(text: 'Operations');

  final _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploadingImage = false;

  bool _isEditing = false;
  Expense? _existingExpense;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(categoryProvider.notifier).fetchCategories(all: false).then((_) {
        final cats = ref.read(categoryProvider).categories
            .where((c) => c.isActive && c.type == 'expense')
            .toList();
        if (cats.isNotEmpty && _selectedCategory.isEmpty) {
          setState(() {
            _selectedCategory = cats.first.name;
          });
        }
      });
      ref.read(walletProvider.notifier).fetchWallets().then((_) {
        if (!_isEditing) {
          final matching = ref.read(walletProvider).wallets.where((w) => w.currency == _selectedCurrency).toList();
          if (matching.isNotEmpty) {
            setState(() {
              _selectedWalletId = matching.first.id;
            });
          }
        }
      });
    });
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
        _selectedWalletId = _existingExpense!.walletId;
        
        _amountController.text = _existingExpense!.amount.toString();
        _locationController.text = _existingExpense!.location ?? '';
        _vendorController.text = _existingExpense!.vendor ?? '';
        _projectController.text = _existingExpense!.project ?? 'Operations';
        _noteController.text = _existingExpense!.note ?? '';
      });
    }
  }

  String _getFullPhotoUrl(String photoUrl) {
    if (photoUrl.isEmpty) return '';
    if (photoUrl.startsWith('http')) return photoUrl;
    final serverBase = Constants.baseUrl.replaceAll('/api', '');
    return '$serverBase$photoUrl';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _locationController.dispose();
    _vendorController.dispose();
    _noteController.dispose();
    _projectController.dispose();
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
      setState(() {
        _isUploadingImage = true;
      });

      String? photoUrl = _existingExpense?.photoUrl;

      // If a new image was picked, upload it first
      if (_selectedImage != null && _imageBytes != null) {
        try {
          final apiService = ref.read(apiServiceProvider);
          photoUrl = await apiService.uploadReceipt(
            _imageBytes!,
            _selectedImage!.name,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload receipt: $e')),
            );
          }
          setState(() {
            _isUploadingImage = false;
          });
          return;
        }
      }

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
        vendor: _vendorController.text.isNotEmpty ? _vendorController.text : null,
        project: _projectController.text.trim().isNotEmpty ? _projectController.text.trim() : 'Operations',
        photoUrl: photoUrl,
        userId: _existingExpense?.userId,
        walletId: _selectedWalletId,
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
      } finally {
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });
        }
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
                controller: _projectController,
                decoration: const InputDecoration(
                  labelText: 'Project',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Project is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vendorController,
                decoration: const InputDecoration(
                  labelText: 'Vendor',
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
              Consumer(
                builder: (context, ref, child) {
                  final catsState = ref.watch(categoryProvider);
                  final expenseCats = catsState.categories
                      .where((c) => c.isActive && c.type == 'expense')
                      .toList();

                  if (catsState.isLoading && expenseCats.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator())),
                    );
                  }

                  if (expenseCats.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No categories available'),
                    );
                  }

                  // If selected category is empty, default to first category
                  if (_selectedCategory.isEmpty) {
                    Future.microtask(() {
                      setState(() {
                        _selectedCategory = expenseCats.first.name;
                      });
                    });
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: expenseCats.map((category) {
                      final parsedColor = ColorParser.fromHex(category.color);
                      final iconData = CategoryIconHelper.getIcon(category.icon);

                      return CategoryChip(
                        label: category.name,
                        icon: iconData,
                        color: parsedColor,
                        isSelected: _selectedCategory == category.name,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = category.name);
                          }
                        },
                      );
                    }).toList(),
                  );
                },
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
                    decoration: const InputDecoration(
                      labelText: 'Deduct From Account / Wallet',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('No Account (Generic Balance)'),
                      ),
                      ...filteredWallets.map((w) => DropdownMenuItem<int?>(
                        value: w.id,
                        child: Text('${w.name} (${w.currency})'),
                      )),
                    ],
                    onChanged: (val) => setState(() => _selectedWalletId = val),
                  );
                },
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
                  _buildAttachButton(Icons.camera_alt, 'TAKE\nPHOTO', () => _pickImage(ImageSource.camera)),
                  _buildAttachButton(Icons.image, 'PICK\nPHOTO', () => _pickImage(ImageSource.gallery)),
                  _buildAttachButton(Icons.picture_as_pdf, 'PICK\nPDF', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Only image attachments are currently supported')),
                    );
                  }),
                ],
              ),
              if (_selectedImage != null && _imageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                        onPressed: () => setState(() {
                          _selectedImage = null;
                          _imageBytes = null;
                        }),
                      ),
                    ],
                  ),
                )
              else if (_existingExpense?.photoUrl != null && _existingExpense!.photoUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _getFullPhotoUrl(_existingExpense!.photoUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.image_not_supported, size: 50));
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 30),
                        onPressed: () => setState(() {
                          _existingExpense = _existingExpense!.copyWith(photoUrl: '');
                        }),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: (isLoading || _isUploadingImage) ? null : _saveExpense,
                child: (isLoading || _isUploadingImage)
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

  Widget _buildAttachButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
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
