import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/enums.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../widgets/expense_card.dart';
import '../widgets/category_chip.dart';
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

    return Scaffold(
      drawer: MediaQuery.of(context).size.width < 600 ? const AppNavigationDrawer() : null,
      appBar: AppBar(

        title: const Text('Expenses'),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search vendor, note, location...',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CategoryChip(
                    label: 'All',
                    isSelected: _selectedCategories.isEmpty,
                    onSelected: (selected) {
                      setState(() => _selectedCategories.clear());
                      _fetchData();
                    },
                  ),
                  const SizedBox(width: 8),
                  ...categoryState.categories
                      .where((cat) => cat.type == 'expense')
                      .map((category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CategoryChip(
                              label: category.name,
                              icon: CategoryIconHelper.getIcon(category.icon),
                              color: ColorParser.fromHex(category.color),
                              isSelected: _selectedCategories.contains(category.name),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategories.add(category.name);
                                  } else {
                                    _selectedCategories.remove(category.name);
                                  }
                                });
                                _fetchData();
                              },
                            ),
                          )),
                ],
              ),
            ),
          ),
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              child: expenseState.isLoading && expenseState.expenses.isEmpty
                  ? const LoadingWidget()
                  : expenseState.expenses.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('No expenses found.')),
                          ],
                        )
                      : ListView.builder(
                          itemCount: expenseState.expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenseState.expenses[index];
                            final canEdit = expense.userId == user?.id || isAdmin;

                            return canEdit
                                ? Dismissible(
                                    key: Key('expense_${expense.id}'),
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
                                          title: const Text('Delete Expense'),
                                          content: const Text('Are you sure you want to delete this expense?'),
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
                                      if (expense.id != null) {
                                        ref.read(expenseProvider.notifier).deleteExpense(expense.id!);
                                      }
                                    },
                                    child: ExpenseCard(
                                      expense: expense,
                                      onTap: () => context.go('/expenses/edit', extra: expense.id),
                                    ),
                                  )
                                : ExpenseCard(
                                    expense: expense,
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('You cannot edit this expense')),
                                      );
                                    },
                                  );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/expenses/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
