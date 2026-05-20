import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/settings/stat_card.dart';
import '../../theme/app_theme.dart';

class SystemStatsSection extends ConsumerStatefulWidget {
  const SystemStatsSection({super.key});

  @override
  ConsumerState<SystemStatsSection> createState() => _SystemStatsSectionState();
}

class _SystemStatsSectionState extends ConsumerState<SystemStatsSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(statsProvider.notifier).fetchAll());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    if (state.isLoading && state.stats.totalUsers == 0) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            StatCard(label: 'Users', value: '${state.stats.totalUsers}', icon: Icons.people),
            StatCard(label: 'Expenses', value: '${state.stats.totalExpenses}', icon: Icons.receipt_long, color: AppTheme.errorColor),
            StatCard(label: 'Incomes', value: '${state.stats.totalIncomes}', icon: Icons.arrow_downward, color: Colors.green),
            StatCard(label: 'Transfers', value: '${state.stats.totalTransfers}', icon: Icons.swap_horiz, color: Colors.blue),
            StatCard(label: 'Categories', value: '${state.stats.activeCategories}/${state.stats.totalCategories}', icon: Icons.category, color: Colors.orange),
            StatCard(label: 'Net (USD)', value: fmt.format(state.stats.totalIncomeAmountUsd - state.stats.totalExpenseAmountUsd), icon: Icons.account_balance, color: AppTheme.primaryColor),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Recent Audit Log', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 8),
        if (state.auditLogs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No audit entries yet', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          )
        else
          ...state.auditLogs.take(10).map((log) => Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              leading: Icon(
                _iconForAction(log.action),
                size: 20,
                color: AppTheme.primaryColor,
              ),
              title: Text(
                _formatAction(log.action),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${log.userEmail}  •  ${log.createdAt.substring(0, 16).replaceAll('T', ' ')}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          )),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(state.error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 12)),
          ),
      ],
    );
  }

  IconData _iconForAction(String action) {
    if (action.contains('settings')) return Icons.settings;
    if (action.contains('category')) return Icons.category;
    if (action.contains('user') || action.contains('password')) return Icons.person;
    return Icons.history;
  }

  String _formatAction(String action) {
    return action.replaceAll('_', ' ').split(' ').map((w) =>
      w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
    ).join(' ');
  }
}
