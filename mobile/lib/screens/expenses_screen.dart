import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../widgets/expense_card.dart';
import '../widgets/category_chip.dart';
import '../utils/constants.dart';
import '../utils/downloader.dart';
import '../utils/color_parser.dart';
import '../utils/category_icons.dart';
import '../services/api_service.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String? _selectedCategory;
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _fetchData();
      ref.read(categoryProvider.notifier).fetchCategories(all: false);
      final user = ref.read(authProvider).user;
      if (user != null && user.role.name != 'user') {
        ref.read(userProvider.notifier).fetchUsers();
      }
    });
  }

  Future<void> _fetchData() async {
    await ref.read(expenseProvider.notifier).fetchExpenses(
      category: _selectedCategory,
      userId: _selectedUserId,
    );
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
      
      if (format == 'csv') {
        bytes = await api.downloadExpensesCsv(
          category: _selectedCategory,
          userId: _selectedUserId,
        );
        filename = 'expenses_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      } else {
        bytes = await api.downloadExpensesPdf(
          category: _selectedCategory,
          userId: _selectedUserId,
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

    return Scaffold(
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
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Toggle filter visibility
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CategoryChip(
                    label: 'All',
                    isSelected: _selectedCategory == null,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = null);
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
                              isSelected: _selectedCategory == category.name,
                              onSelected: (selected) {
                                setState(() => _selectedCategory = selected ? category.name : null);
                                _fetchData();
                              },
                            ),
                          )),
                ],
              ),
            ),
          ),
          if (isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: DropdownButtonFormField<int?>(
                value: _selectedUserId,
                decoration: const InputDecoration(
                  labelText: 'Filter by User',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All Users')),
                  ...userState.users.map((u) => DropdownMenuItem<int?>(
                    value: u.id,
                    child: Text(u.name),
                  )),
                ],
                onChanged: (val) {
                  setState(() => _selectedUserId = val);
                  _fetchData();
                },
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
