import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/enums.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/transfer_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../widgets/add_income_dialog.dart';
import '../widgets/add_transfer_dialog.dart';
import '../utils/downloader.dart';
import '../utils/color_parser.dart';
import '../utils/category_icons.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/navigation_drawer.dart';


class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  List<String> _selectedCategories = [];
  List<String> _selectedProjects = [];
  String _searchText = '';
  DateTimeRange? _dateRange;
  double? _minAmount;
  double? _maxAmount;
  String _status = 'all'; // 'all', 'has_receipt', 'missing_receipt', 'self_receipt', 'standard_receipt'
  int? _selectedUserId;
  String _selectedType = 'ALL'; // 'ALL', 'EXPENSE', 'INCOME', 'TRANSFER'

  List<Map<String, dynamic>> _savedFiltersList = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadSavedFilters();
      _fetchData();
      ref.read(categoryProvider.notifier).fetchCategories(all: false);
      final user = ref.read(authProvider).user;
      if (user != null && user.role.name != 'user') {
        ref.read(userProvider.notifier).fetchUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedFilters() async {
    try {
      final jsonStr = await storageService.getFavoriteFilters();
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        setState(() {
          _savedFiltersList = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading saved filters: $e');
    }
  }

  Future<void> _deleteFavoriteFilter(int index) async {
    final updatedList = List<Map<String, dynamic>>.from(_savedFiltersList)..removeAt(index);
    final jsonStr = json.encode(updatedList);
    await storageService.saveFavoriteFilters(jsonStr);
    
    setState(() {
      _savedFiltersList = updatedList;
    });
  }

  List<String> _getUniqueProjects() {
    final expenses = ref.read(expenseProvider).expenses;
    final projects = expenses
        .map((e) => e.project)
        .where((p) => p != null && p.trim().isNotEmpty)
        .map((p) => p!.trim())
        .toSet()
        .toList();
    final defaultProjects = ['Operations', 'Missions', 'Worship Night', 'Youth Camp'];
    for (var dp in defaultProjects) {
      if (!projects.contains(dp)) {
        projects.add(dp);
      }
    }
    projects.sort();
    return projects;
  }

  Future<void> _fetchData() async {
    String? startStr;
    String? endStr;
    if (_dateRange != null) {
      startStr = _dateRange!.start.toIso8601String();
      endStr = _dateRange!.end.toIso8601String();
    }
    await ref.read(expenseProvider.notifier).fetchExpenses(
      categories: _selectedCategories.isEmpty ? null : _selectedCategories,
      userId: _selectedUserId,
      startDate: startStr,
      endDate: endStr,
      search: _searchText.isNotEmpty ? _searchText : null,
      minAmount: _minAmount,
      maxAmount: _maxAmount,
      status: _status,
      projects: _selectedProjects.isEmpty ? null : _selectedProjects,
    );
    await ref.read(incomeProvider.notifier).fetchIncomes(
      userId: _selectedUserId,
      startDate: startStr,
      endDate: endStr,
      projects: _selectedProjects.isEmpty ? null : _selectedProjects,
    );
    await ref.read(transferProvider.notifier).fetchTransfers(
      userId: _selectedUserId,
      startDate: startStr,
      endDate: endStr,
      projects: _selectedProjects.isEmpty ? null : _selectedProjects,
    );
  }

  void _onSearchChanged(String val) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchText = val;
      });
      _fetchData();
    });
  }

  Future<void> _exportData(String format) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final api = ref.read(apiServiceProvider);
      List<int> bytes;
      String filename;
      
      String? startStr;
      String? endStr;
      if (_dateRange != null) {
        startStr = _dateRange!.start.toIso8601String();
        endStr = _dateRange!.end.toIso8601String();
      }

      if (format == 'csv') {
        bytes = await api.downloadExpensesCsv(
          categories: _selectedCategories.isEmpty ? null : _selectedCategories,
          userId: _selectedUserId,
          startDate: startStr,
          endDate: endStr,
          search: _searchText.isNotEmpty ? _searchText : null,
          minAmount: _minAmount,
          maxAmount: _maxAmount,
          status: _status,
          projects: _selectedProjects.isEmpty ? null : _selectedProjects,
        );
        filename = 'expenses_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      } else {
        bytes = await api.downloadExpensesPdf(
          categories: _selectedCategories.isEmpty ? null : _selectedCategories,
          userId: _selectedUserId,
          startDate: startStr,
          endDate: endStr,
          search: _searchText.isNotEmpty ? _searchText : null,
          minAmount: _minAmount,
          maxAmount: _maxAmount,
          status: _status,
          projects: _selectedProjects.isEmpty ? null : _selectedProjects,
        );
        filename = 'expenses_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      if (mounted) Navigator.of(context).pop();

      await downloadFile(bytes, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report exported successfully as ${format.toUpperCase()}!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export report: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildStatusChip(String value, String label, String currentValue, ValueChanged<String> onSelected) {
    final isSelected = currentValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onSelected(value);
        }
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    CategoryState categoryState,
    UserState userState,
    bool isAdmin,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        List<String> localCategories = List.from(_selectedCategories);
        List<String> localProjects = List.from(_selectedProjects);
        DateTimeRange? localDateRange = _dateRange;
        String localStatus = _status;
        int? localUserId = _selectedUserId;

        final minController = TextEditingController(text: _minAmount?.toString() ?? '');
        final maxController = TextEditingController(text: _maxAmount?.toString() ?? '');
        final filterNameController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Advanced Filters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              localCategories.clear();
                              localProjects.clear();
                              localDateRange = null;
                              minController.clear();
                              maxController.clear();
                              localStatus = 'all';
                              localUserId = null;
                            });
                          },
                          child: const Text('Reset All'),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_savedFiltersList.isNotEmpty) ...[
                      const Text(
                        'Favorite Filters',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 45,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _savedFiltersList.length,
                          itemBuilder: (context, index) {
                            final filter = _savedFiltersList[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InputChip(
                                label: Text(filter['name']),
                                backgroundColor: Colors.grey[100],
                                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                                labelStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                ),
                                onSelected: (selected) {
                                  setSheetState(() {
                                    localCategories = List<String>.from(filter['categories'] ?? []);
                                    localProjects = List<String>.from(filter['projects'] ?? []);
                                    localUserId = filter['userId'];
                                    final minAmt = filter['minAmount'] != null ? double.tryParse(filter['minAmount'].toString()) : null;
                                    final maxAmt = filter['maxAmount'] != null ? double.tryParse(filter['maxAmount'].toString()) : null;
                                    minController.text = minAmt?.toString() ?? '';
                                    maxController.text = maxAmt?.toString() ?? '';
                                    localStatus = filter['status'] ?? 'all';
                                    if (filter['dateRange'] != null) {
                                      final start = DateTime.parse(filter['dateRange']['start']);
                                      final end = DateTime.parse(filter['dateRange']['end']);
                                      localDateRange = DateTimeRange(start: start, end: end);
                                    } else {
                                      localDateRange = null;
                                    }
                                  });
                                },
                                onDeleted: () async {
                                  await _deleteFavoriteFilter(index);
                                  setSheetState(() {});
                                },
                                deleteIcon: const Icon(Icons.cancel, size: 16),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: filterNameController,
                            decoration: const InputDecoration(
                              hintText: 'Save current filters as...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final name = filterNameController.text.trim();
                            if (name.isNotEmpty) {
                              final newFilter = {
                                'name': name,
                                'search': _searchController.text.trim(),
                                'categories': localCategories,
                                'projects': localProjects,
                                'userId': localUserId,
                                'minAmount': double.tryParse(minController.text),
                                'maxAmount': double.tryParse(maxController.text),
                                'status': localStatus,
                                'dateRange': localDateRange != null ? {
                                  'start': localDateRange!.start.toIso8601String(),
                                  'end': localDateRange!.end.toIso8601String(),
                                } : null,
                              };
                              
                              final updatedList = List<Map<String, dynamic>>.from(_savedFiltersList)..add(newFilter);
                              final jsonStr = json.encode(updatedList);
                              await storageService.saveFavoriteFilters(jsonStr);
                              
                              setState(() {
                                _savedFiltersList = updatedList;
                              });
                              setSheetState(() {
                                filterNameController.clear();
                              });
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Filter template saved successfully!')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Date Range',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          initialDateRange: localDateRange,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primaryColor,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black87,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() {
                            localDateRange = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                localDateRange == null
                                    ? 'All Dates'
                                    : '${DateFormat('MMM dd, yyyy').format(localDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(localDateRange!.end)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            if (localDateRange != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setSheetState(() {
                                    localDateRange = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Amount Range',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Min Amount',
                              prefixText: '\$ ',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: maxController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Max Amount',
                              prefixText: '\$ ',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Receipt Status',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildStatusChip('all', 'All Receipts', localStatus, (status) {
                          setSheetState(() => localStatus = status);
                        }),
                        _buildStatusChip('has_receipt', 'Has Receipt', localStatus, (status) {
                          setSheetState(() => localStatus = status);
                        }),
                        _buildStatusChip('missing_receipt', 'Missing Receipt', localStatus, (status) {
                          setSheetState(() => localStatus = status);
                        }),
                        _buildStatusChip('self_receipt', 'Self Receipt', localStatus, (status) {
                          setSheetState(() => localStatus = status);
                        }),
                        _buildStatusChip('standard_receipt', 'Standard', localStatus, (status) {
                          setSheetState(() => localStatus = status);
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Filter by Categories',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: categoryState.categories
                          .where((cat) => cat.type == 'expense')
                          .map((category) {
                        final isSelected = localCategories.contains(category.name);
                        return FilterChip(
                          avatar: Icon(
                            CategoryIconHelper.getIcon(category.icon),
                            size: 16,
                            color: isSelected ? ColorParser.fromHex(category.color) : Colors.grey,
                          ),
                          label: Text(category.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setSheetState(() {
                              if (selected) {
                                localCategories.add(category.name);
                              } else {
                                localCategories.remove(category.name);
                              }
                            });
                          },
                          selectedColor: ColorParser.fromHex(category.color).withOpacity(0.2),
                          checkmarkColor: ColorParser.fromHex(category.color),
                          labelStyle: TextStyle(
                            color: isSelected ? ColorParser.fromHex(category.color) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Filter by Projects',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _getUniqueProjects().map((project) {
                        final isSelected = localProjects.contains(project);
                        return FilterChip(
                          avatar: Icon(
                            Icons.assignment,
                            size: 16,
                            color: isSelected ? AppTheme.primaryColor : Colors.grey,
                          ),
                          label: Text(project),
                          selected: isSelected,
                          onSelected: (selected) {
                            setSheetState(() {
                              if (selected) {
                                localProjects.add(project);
                              } else {
                                localProjects.remove(project);
                              }
                            });
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          checkmarkColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    if (isAdmin) ...[
                      const Text(
                        'Filter by User',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        value: localUserId,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('All Users')),
                          ...userState.users.map((u) => DropdownMenuItem<int?>(
                            value: u.id,
                            child: Text(u.name),
                          )),
                        ],
                        onChanged: (val) {
                          setSheetState(() {
                            localUserId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategories = localCategories;
                            _selectedProjects = localProjects;
                            _dateRange = localDateRange;
                            _minAmount = double.tryParse(minController.text);
                            _maxAmount = double.tryParse(maxController.text);
                            _status = localStatus;
                            _selectedUserId = localUserId;
                          });
                          _fetchData();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final incomeState = ref.watch(incomeProvider);
    final transferState = ref.watch(transferProvider);
    final user = ref.watch(authProvider).user;
    final userState = ref.watch(userProvider);
    final categoryState = ref.watch(categoryProvider);
    final isAdmin = user != null && user.role.name != 'user';

    ref.listen(expenseProvider, (previous, next) {
      if (next.error != null && (previous == null || previous.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppTheme.errorColor),
        );
      }
    });

    final hasActiveFilters = _selectedCategories.isNotEmpty ||
        _selectedProjects.isNotEmpty ||
        _dateRange != null ||
        _minAmount != null ||
        _maxAmount != null ||
        _status != 'all' ||
        _selectedUserId != null;

    // Combine transactions
    final List<_UnifiedTx> allTxs = [];

    // Add Expenses
    for (var e in expenseState.expenses) {
      allTxs.add(_UnifiedTx(
        id: 'exp_${e.id}',
        title: e.category,
        amount: e.amount,
        currency: e.currency,
        date: e.date,
        project: e.project ?? 'Operations',
        type: 'expense',
        originalId: e.id!,
        userId: e.userId,
      ));
    }

    // Add Incomes
    for (var i in incomeState.incomes) {
      allTxs.add(_UnifiedTx(
        id: 'inc_${i.id}',
        title: i.source,
        amount: i.amount,
        currency: i.currency,
        date: i.date,
        project: 'Income',
        type: 'income',
        originalId: i.id!,
        userId: i.userId,
      ));
    }

    // Add Transfers
    for (var t in transferState.transfers) {
      allTxs.add(_UnifiedTx(
        id: 'trn_${t.id}',
        title: 'Transfer',
        amount: t.amountFrom,
        currency: t.currencyFrom,
        date: t.date,
        project: t.note ?? 'Transfer',
        type: 'transfer',
        originalId: t.id!,
        userId: t.userId,
      ));
    }

    // Sort chronologically (newest first)
    allTxs.sort((a, b) => b.date.compareTo(a.date));

    // Filter combined list
    final filteredTxs = allTxs.where((tx) {
      // 1. Filter by Type
      if (_selectedType != 'ALL' && tx.type.toUpperCase() != _selectedType) {
        return false;
      }
      
      // 2. Filter by Search Text
      if (_searchText.isNotEmpty) {
        final titleMatch = tx.title.toLowerCase().contains(_searchText.toLowerCase());
        final projectMatch = tx.project.toLowerCase().contains(_searchText.toLowerCase());
        if (!titleMatch && !projectMatch) return false;
      }
      
      // 3. Filter by Category (only applies to expenses)
      if (_selectedCategories.isNotEmpty) {
        if (tx.type != 'expense' || !_selectedCategories.contains(tx.title)) {
          return false;
        }
      }
      
      // 4. Filter by Project
      if (_selectedProjects.isNotEmpty) {
        if (!_selectedProjects.contains(tx.project)) {
          return false;
        }
      }
      
      // 5. Filter by Min/Max Amount
      if (_minAmount != null && tx.amount < _minAmount!) return false;
      if (_maxAmount != null && tx.amount > _maxAmount!) return false;
      
      return true;
    }).toList();

    final isLoading = expenseState.isLoading || incomeState.isLoading || transferState.isLoading;

    return Scaffold(
      drawer: MediaQuery.of(context).size.width < 600 ? const AppNavigationDrawer() : null,
      appBar: AppBar(
        title: const Text('HISTORY'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export Data',
            onSelected: _exportData,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'csv',
                child: ListTile(
                  leading: Icon(Icons.table_chart, color: Colors.green),
                  title: Text('Export to CSV'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text('Export to PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search notes, projects...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchText = '';
                                });
                                _fetchData();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showFilterBottomSheet(context, categoryState, userState, isAdmin),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasActiveFilters ? AppTheme.primaryColor : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.tune,
                      color: hasActiveFilters ? Colors.white : Colors.grey[700],
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Chips (ALL, EXPENSE, INCOME, TRANSFER)
          _buildTypeFilterBar(),

          // Active filter badges
          if (hasActiveFilters)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_selectedCategories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text('Categories (${_selectedCategories.length})'),
                        onDeleted: () {
                          setState(() => _selectedCategories.clear());
                          _fetchData();
                        },
                      ),
                    ),
                  if (_selectedProjects.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text('Projects (${_selectedProjects.length})'),
                        onDeleted: () {
                          setState(() => _selectedProjects.clear());
                          _fetchData();
                        },
                      ),
                    ),
                  if (_dateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(
                          'Date: ${DateFormat('MM/dd').format(_dateRange!.start)} - ${DateFormat('MM/dd').format(_dateRange!.end)}',
                        ),
                        onDeleted: () {
                          setState(() => _dateRange = null);
                          _fetchData();
                        },
                      ),
                    ),
                  if (_minAmount != null || _maxAmount != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(
                          'Amount: ${_minAmount != null ? '\$${_minAmount!.toStringAsFixed(0)}' : '0'} - ${_maxAmount != null ? '\$${_maxAmount!.toStringAsFixed(0)}' : 'Any'}',
                        ),
                        onDeleted: () {
                          setState(() {
                            _minAmount = null;
                            _maxAmount = null;
                          });
                          _fetchData();
                        },
                      ),
                    ),
                  if (_status != 'all')
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text('Status: ${_status.replaceAll('_', ' ')}'),
                        onDeleted: () {
                          setState(() => _status = 'all');
                          _fetchData();
                        },
                      ),
                    ),
                  if (_selectedUserId != null && isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Consumer(
                          builder: (context, ref, child) {
                            final userVal = userState.users.firstWhere(
                              (u) => u.id == _selectedUserId,
                              orElse: () => User(
                                id: 0,
                                name: 'Unknown',
                                email: '',
                                role: UserRole.user,
                                isApproved: false,
                                createdAt: DateTime.now(),
                              ),
                            );
                            return Text('User: ${userVal.name}');
                          },
                        ),
                        onDeleted: () {
                          setState(() => _selectedUserId = null);
                          _fetchData();
                        },
                      ),
                    ),
                ],
              ),
            ),

          // TRANSACTION LOGS Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TRANSACTION LOGS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${filteredTxs.length} ITEMS',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // List Items
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              child: isLoading && filteredTxs.isEmpty
                  ? const LoadingWidget()
                  : filteredTxs.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('No transactions found.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: filteredTxs.length,
                          itemBuilder: (context, index) {
                            final tx = filteredTxs[index];
                            final canEdit = tx.userId == user?.id || isAdmin;

                            return canEdit
                                ? Dismissible(
                                    key: Key('tx_${tx.id}'),
                                    background: Container(
                                      color: AppTheme.errorColor,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    direction: DismissDirection.endToStart,
                                    confirmDismiss: (direction) async {
                                      return await showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text('Delete ${tx.type.toUpperCase()}'),
                                          content: Text('Are you sure you want to delete this ${tx.type}?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(false),
                                              child: const Text('CANCEL'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(true),
                                              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onDismissed: (direction) {
                                      if (tx.type == 'expense') {
                                        ref.read(expenseProvider.notifier).deleteExpense(tx.originalId);
                                      } else if (tx.type == 'income') {
                                        ref.read(incomeProvider.notifier).deleteIncome(tx.originalId);
                                      } else {
                                        ref.read(transferProvider.notifier).deleteTransfer(tx.originalId);
                                      }
                                    },
                                    child: _buildTransactionCard(tx),
                                  )
                                : _buildTransactionCard(tx);
                          },
                        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildTypeFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTypeChip('ALL'),
          _buildTypeChip('EXPENSE'),
          _buildTypeChip('INCOME'),
          _buildTypeChip('TRANSFER'),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(
        type,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade500,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
          });
        }
      },
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  Widget _buildTransactionCard(_UnifiedTx tx) {
    IconData arrowIcon;
    Color circleBg;
    Color iconColor;
    Color amountColor;
    String amountSign;

    if (tx.type == 'expense') {
      arrowIcon = Icons.north_east;
      circleBg = AppTheme.primaryColor.withOpacity(0.08);
      iconColor = AppTheme.primaryColor;
      amountColor = const Color(0xFFE5A93C); // Amber/gold
      amountSign = '-';
    } else if (tx.type == 'income') {
      arrowIcon = Icons.south_west;
      circleBg = const Color(0xFF10B981).withOpacity(0.08); // green
      iconColor = const Color(0xFF10B981);
      amountColor = const Color(0xFF10B981);
      amountSign = '+';
    } else {
      // transfer
      arrowIcon = Icons.swap_horiz;
      circleBg = Colors.blue.withOpacity(0.08);
      iconColor = Colors.blue;
      amountColor = Colors.blue;
      amountSign = '⇄';
    }

    final formatter = NumberFormat.simpleCurrency(name: tx.currency);
    final formattedAmount = formatter.format(tx.amount).replaceAll(formatter.currencySymbol, '');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: circleBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            arrowIcon,
            color: iconColor,
            size: 20,
          ),
        ),
        title: Text(
          tx.title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '${DateFormat('yyyy-MM-dd').format(tx.date)}  •  ${tx.project.toUpperCase()}',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$amountSign$formattedAmount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: amountColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              tx.currency,
              style: TextStyle(
                fontSize: 11,
                color: amountColor.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        onTap: () {
          if (tx.type == 'expense') {
            context.go('/expenses/edit', extra: tx.originalId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Details for ${tx.type} can be viewed on Dashboard')),
            );
          }
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomBarItem(
              icon: Icons.history,
              label: 'LOGS',
              isActive: true,
              onTap: () {
                _fetchData();
              },
            ),
            _buildBottomBarItem(
              icon: Icons.remove,
              label: 'SPENT',
              isActive: false,
              onTap: () => context.go('/expenses/add'),
            ),
            GestureDetector(
              onTap: () => context.go('/expenses/add'),
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            _buildBottomBarItem(
              icon: Icons.add,
              label: 'EARNED',
              isActive: false,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddIncomeDialog(),
                ).then((_) => _fetchData());
              },
            ),
            _buildBottomBarItem(
              icon: Icons.swap_horiz,
              label: 'MOVE',
              isActive: false,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddTransferDialog(),
                ).then((_) => _fetchData());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = AppTheme.primaryColor;
    final inactiveColor = Colors.grey.shade400;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnifiedTx {
  final String id;
  final String title;
  final double amount;
  final String currency;
  final DateTime date;
  final String project;
  final String type; // 'expense', 'income', 'transfer'
  final int originalId;
  final int? userId;

  _UnifiedTx({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    required this.project,
    required this.type,
    required this.originalId,
    this.userId,
  });
}
