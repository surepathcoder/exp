import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../utils/currency_converter.dart';
import '../../theme/app_theme.dart';

class SummaryCards extends ConsumerWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final expenses = ref.watch(expenseProvider).expenses;
    final incomes = ref.watch(incomeProvider).incomes;

    double totalBalance = 0;
    dashboardState.balances.forEach((currency, amount) {
      totalBalance += CurrencyConverter.convertToUsd(amount, currency);
    });

    final now = DateTime.now();
    final firstDayThisMonth = DateTime(now.year, now.month, 1);
    final firstDayLastMonth = now.month == 1 
        ? DateTime(now.year - 1, 12, 1) 
        : DateTime(now.year, now.month - 1, 1);

    double incomeThisMonth = 0;
    double incomeLastMonth = 0;
    for (var inc in incomes) {
      final usd = CurrencyConverter.convertToUsd(inc.amount, inc.currency);
      if (inc.date.isAfter(firstDayThisMonth)) {
        incomeThisMonth += usd;
      } else if (inc.date.isAfter(firstDayLastMonth) && inc.date.isBefore(firstDayThisMonth)) {
        incomeLastMonth += usd;
      }
    }

    double expenseThisMonth = 0;
    double expenseLastMonth = 0;
    for (var exp in expenses) {
      final usd = CurrencyConverter.convertToUsd(exp.amount, exp.currency);
      if (exp.date.isAfter(firstDayThisMonth)) {
        expenseThisMonth += usd;
      } else if (exp.date.isAfter(firstDayLastMonth) && exp.date.isBefore(firstDayThisMonth)) {
        expenseLastMonth += usd;
      }
    }

    double savingsThisMonth = incomeThisMonth - expenseThisMonth;
    double incomeChange = incomeLastMonth > 0 ? ((incomeThisMonth - incomeLastMonth) / incomeLastMonth) * 100 : 0.0;
    double expenseChange = expenseLastMonth > 0 ? ((expenseThisMonth - expenseLastMonth) / expenseLastMonth) * 100 : 0.0;
    
    double previousBalance = totalBalance - savingsThisMonth;
    double balanceChange = previousBalance > 0 ? (savingsThisMonth / previousBalance) * 100 : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final crossAxisCount = isWide ? 4 : 2;
        final aspectRatio = isWide ? 1.6 : 1.35;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: [
            _buildCard(
              context: context,
              title: 'Total Balance',
              amount: totalBalance,
              changePercent: balanceChange,
              subtitle: 'from last month',
              icon: Icons.account_balance_wallet_outlined,
              color: AppTheme.primaryColor,
              isBalance: true,
            ),
            _buildCard(
              context: context,
              title: 'Savings',
              amount: savingsThisMonth,
              changePercent: incomeThisMonth > 0 ? (savingsThisMonth / incomeThisMonth) * 100 : 0.0,
              subtitle: 'of income saved',
              icon: Icons.savings_outlined,
              color: Colors.purple,
              isSavings: true,
            ),
            _buildCard(
              context: context,
              title: 'Total Income',
              amount: incomeThisMonth,
              changePercent: incomeChange,
              subtitle: 'vs last month',
              icon: Icons.arrow_downward,
              color: Colors.green,
              isPositiveTrendGreen: true,
            ),
            _buildCard(
              context: context,
              title: 'Total Expenses',
              amount: expenseThisMonth,
              changePercent: expenseChange,
              subtitle: 'vs last month',
              icon: Icons.arrow_upward,
              color: AppTheme.errorColor,
              isPositiveTrendGreen: false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required double amount,
    required double changePercent,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isBalance = false,
    bool isSavings = false,
    bool? isPositiveTrendGreen,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    Color trendColor = Colors.grey;
    IconData trendIcon = Icons.trending_flat;
    
    if (changePercent > 0.01) {
      trendIcon = Icons.trending_up;
      if (isBalance || isSavings) {
        trendColor = Colors.green;
      } else {
        trendColor = isPositiveTrendGreen! ? Colors.green : AppTheme.errorColor;
      }
    } else if (changePercent < -0.01) {
      trendIcon = Icons.trending_down;
      if (isBalance || isSavings) {
        trendColor = AppTheme.errorColor;
      } else {
        trendColor = isPositiveTrendGreen! ? AppTheme.errorColor : Colors.green;
      }
    }

    final isNegative = amount < 0;
    final displayAmount = isNegative ? -amount : amount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[500],
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${isNegative ? '-' : ''}${currencyFormat.format(displayAmount)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: trendColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(trendIcon, size: 12, color: trendColor),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      '${changePercent.abs().toStringAsFixed(0)}% $subtitle',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
