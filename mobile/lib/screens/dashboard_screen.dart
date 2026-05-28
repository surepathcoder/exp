import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/dashboard/header_section.dart';
import '../widgets/dashboard/summary_cards.dart';
import '../widgets/dashboard/trend_line_chart.dart';
import '../widgets/dashboard/category_pie_chart.dart';
import '../widgets/dashboard/income_expense_bar_chart.dart';
import '../widgets/dashboard/recent_transactions_section.dart';
import '../widgets/navigation_drawer.dart';
import '../widgets/add_income_dialog.dart';
import '../widgets/add_transfer_dialog.dart';
import '../widgets/currency_exchange_dialog.dart';
import '../widgets/dashboard/wallet_list.dart';
import '../providers/wallet_provider.dart';
import '../widgets/dashboard/project_portfolio_section.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _refreshData());
  }

  Future<void> _refreshData() async {
    await Future.wait([
      ref.read(dashboardProvider.notifier).fetchDashboardData(),
      ref.read(expenseProvider.notifier).fetchExpenses(),
      ref.read(incomeProvider.notifier).fetchIncomes(),
      ref.read(walletProvider.notifier).fetchWallets(),
    ]);
  }

  Widget _buildActionButtons(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    Widget buildButton(String label, VoidCallback onTap) {
      return Expanded(
        child: Material(
          color: primaryColor,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget buildFullWidthButton(String label, VoidCallback onTap) {
      return Material(
        color: primaryColor,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildFullWidthButton('VIEW TRANSACTIONS', () {
          context.go('/expenses');
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            buildButton('NEW EXPENSE', () {
              context.go('/expenses/add');
            }),
            const SizedBox(width: 8),
            buildButton('CURRENCY EXCH.', () {
              showDialog(
                context: context,
                builder: (context) => const CurrencyExchangeDialog(),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            buildButton('NEW INCOME', () {
              showDialog(
                context: context,
                builder: (context) => const AddIncomeDialog(),
              );
            }),
            const SizedBox(width: 8),
            buildButton('NEW TRANSFER', () {
              showDialog(
                context: context,
                builder: (context) => const AddTransferDialog(),
              );
            }),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final expenseState = ref.watch(expenseProvider);
    final incomeState = ref.watch(incomeProvider);

    final isInitialLoad = dashboardState.isLoading &&
        dashboardState.balances.values.every((v) => v == 0) &&
        expenseState.expenses.isEmpty &&
        incomeState.incomes.isEmpty;

    if (isInitialLoad) {
      return const Scaffold(
        body: Center(child: LoadingWidget()),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: isMobile ? const AppNavigationDrawer() : null,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    HeaderSection(),
                    SizedBox(height: 12),
                    WalletList(),
                    SizedBox(height: 16),
                    SummaryCards(),
                    SizedBox(height: 16),
                    ProjectPortfolioSection(),
                    SizedBox(height: 16),
                    TrendLineChart(),
                    SizedBox(height: 16),
                    CategoryPieChart(),
                    SizedBox(height: 16),
                    IncomeExpenseBarChart(),
                    SizedBox(height: 16),
                    RecentTransactionsSection(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0, top: 8.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildActionButtons(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

