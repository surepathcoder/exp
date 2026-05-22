import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    ]);
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              HeaderSection(),
              SizedBox(height: 12),
              SummaryCards(),
              SizedBox(height: 16),
              TrendLineChart(),
              SizedBox(height: 16),
              CategoryPieChart(),
              SizedBox(height: 16),
              IncomeExpenseBarChart(),
              SizedBox(height: 16),
              RecentTransactionsSection(),
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
