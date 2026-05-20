import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../widgets/expense_card.dart';
import '../utils/currency_converter.dart';
import '../widgets/add_income_dialog.dart';
import '../widgets/add_transfer_dialog.dart';
import '../widgets/currency_exchange_dialog.dart';
import '../widgets/notification_bell.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).fetchDashboardData();
      ref.read(expenseProvider.notifier).fetchExpenses();
    });
  }

  double _calculateTotalUsd(Map<String, double> balances) {
    double total = 0;
    balances.forEach((currency, amount) {
      total += CurrencyConverter.convertToUsd(amount, currency);
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final expenseState = ref.watch(expenseProvider);

    if (dashboardState.isLoading && dashboardState.balances.values.every((v) => v == 0)) {
      return const LoadingWidget();
    }

    final totalUsd = _calculateTotalUsd(dashboardState.balances);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardProvider.notifier).fetchDashboardData();
              ref.read(expenseProvider.notifier).fetchExpenses();
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).fetchDashboardData();
          await ref.read(expenseProvider.notifier).fetchExpenses();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${authState.user?.name ?? 'User'}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Card(
                color: AppTheme.primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Net Balance (USD)',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(totalUsd),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildBalanceCard('USD', dashboardState.balances['USD'] ?? 0)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildBalanceCard('TZS', dashboardState.balances['TZS'] ?? 0)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildBalanceCard('KES', dashboardState.balances['KES'] ?? 0)),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Self Receipts',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${dashboardState.selfReceiptPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: dashboardState.selfReceiptPercentage > 50 ? Colors.green : AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(Icons.add, 'NEW\nEXPENSE', () => context.go('/expenses/add')),
                  _buildActionButton(Icons.currency_exchange, 'CURRENCY\nEXCH.', () {
                    showDialog(
                      context: context,
                      builder: (context) => const CurrencyExchangeDialog(),
                    );
                  }),
                  _buildActionButton(Icons.arrow_downward, 'NEW\nINCOME', () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddIncomeDialog(),
                    );
                  }),
                  _buildActionButton(Icons.swap_horiz, 'NEW\nTRANSFER', () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddTransferDialog(),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (expenseState.isLoading && expenseState.expenses.isEmpty)
                const LoadingWidget()
              else if (expenseState.expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No transactions found')),
                )
              else
                ...expenseState.expenses.take(5).map((expense) => ExpenseCard(
                  expense: expense,
                  onTap: () => context.go('/expenses/edit', extra: expense.id),
                )).toList(),
              const SizedBox(height: 80), // Padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String currency, double amount) {
    final format = NumberFormat.currency(symbol: '', decimalDigits: currency == 'USD' ? 2 : 0);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currency,
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              format.format(amount),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
