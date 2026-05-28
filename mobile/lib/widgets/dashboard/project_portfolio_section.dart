import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';

class ProjectPortfolioSection extends ConsumerWidget {
  const ProjectPortfolioSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final activeProjects = dashboardState.activeProjects;
    final expiringProjects = dashboardState.expiringProjects;
    
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Expiring Projects Alert Card
        if (expiringProjects.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Expiration Alert',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...expiringProjects.map((p) {
                        final days = p['days_remaining'] as int;
                        final String timeMsg = days < 0
                            ? 'expired ${days.abs()} days ago'
                            : 'expires in $days days';
                        return Text(
                          '• "${p['name']}" $timeMsg (${p['status']})',
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 2. Active Projects Portfolio Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Project Portfolios',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${activeProjects.length} Active',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (activeProjects.isEmpty)
          Card(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.business_center_outlined, color: Colors.grey, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'No active project portfolios',
                      style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeProjects.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final project = activeProjects[index] as Map<String, dynamic>;
              final name = project['name'] as String;
              final currency = project['currency'] as String;
              final budget = (project['budget'] as num?)?.toDouble() ?? 0.0;
              final totalExpenses = (project['total_expenses'] as num?)?.toDouble() ?? 0.0;
              final balance = (project['remaining_balance'] as num?)?.toDouble() ?? 0.0;
              
              // Calculate percent of budget used
              final double percentUsed = budget > 0 ? (totalExpenses / budget).clamp(0.0, 1.0) : 0.0;
              final double percentVal = budget > 0 ? (totalExpenses / budget) * 100 : 0.0;

              final format = NumberFormat.currency(
                symbol: currency == 'USD' ? '\$' : '$currency ',
                decimalDigits: currency == 'USD' ? 2 : 0,
              );

              final isOverBudget = totalExpenses > budget && budget > 0;

              return Card(
                color: Colors.white,
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOverBudget 
                                ? AppTheme.errorColor.withOpacity(0.1) 
                                : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              project['status'].toString().toUpperCase(),
                              style: TextStyle(
                                color: isOverBudget ? AppTheme.errorColor : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (project['description'] != null && project['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          project['description'],
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Divider(height: 20),

                      // Metrics
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetricColumn(
                            'Budget',
                            budget > 0 ? format.format(budget) : 'No Budget Limit',
                            Colors.black87,
                          ),
                          _buildMetricColumn(
                            'Total Expenses',
                            format.format(totalExpenses),
                            isOverBudget ? AppTheme.errorColor : Colors.orange.shade800,
                          ),
                          _buildMetricColumn(
                            'Remaining Balance',
                            format.format(balance),
                            balance >= 0 ? Colors.green.shade700 : AppTheme.errorColor,
                          ),
                        ],
                      ),
                      
                      // Progress Bar if budget is set
                      if (budget > 0) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Budget Used: ${percentVal.toStringAsFixed(1)}%',
                              style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            if (isOverBudget)
                              const Text(
                                'OVER BUDGET!',
                                style: TextStyle(color: AppTheme.errorColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentUsed,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget ? AppTheme.errorColor : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMetricColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
