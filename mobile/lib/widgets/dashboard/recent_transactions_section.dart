import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icons.dart';
import '../../utils/color_parser.dart';

class RecentTransactionsSection extends ConsumerWidget {
  const RecentTransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseProvider).expenses;
    final incomes = ref.watch(incomeProvider).incomes;
    final categoryState = ref.watch(categoryProvider);

    final List<_TxModel> txs = [];
    for (var e in expenses) {
      txs.add(_TxModel(id: 'exp_${e.id}', title: e.category, amount: e.amount, currency: e.currency, date: e.date, isExpense: true, originalId: e.id!));
    }
    for (var i in incomes) {
      txs.add(_TxModel(id: 'inc_${i.id}', title: i.source, amount: i.amount, currency: i.currency, date: i.date, isExpense: false, originalId: i.id!));
    }

    txs.sort((a, b) => b.date.compareTo(a.date));
    final recentTxs = txs.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            TextButton(
              onPressed: () => context.go('/expenses'),
              child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentTxs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: Text('No transactions recorded yet')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentTxs.length,
            itemBuilder: (context, idx) {
              final tx = recentTxs[idx];
              final cat = categoryState.categoriesByName[tx.title];
              IconData iconData;
              Color iconColor;
              if (cat != null) {
                iconData = CategoryIconHelper.getIcon(cat.icon);
                iconColor = ColorParser.fromHex(cat.color);
              } else {
                iconData = tx.isExpense ? Icons.payment : Icons.trending_up;
                iconColor = tx.isExpense ? AppTheme.primaryColor : Colors.green;
                if (tx.isExpense) {
                  switch (tx.title.toLowerCase()) {
                    case 'food':
                    case 'dining':
                    case 'food & drinks':
                      iconData = Icons.restaurant;
                      break;
                    case 'transport':
                    case 'travel':
                      iconData = Icons.directions_car;
                      break;
                    case 'utilities':
                    case 'bills':
                      iconData = Icons.receipt;
                      break;
                    case 'entertainment':
                    case 'leisure':
                      iconData = Icons.movie;
                      break;
                    case 'shopping':
                      iconData = Icons.shopping_bag;
                      break;
                    case 'health':
                    case 'medical':
                      iconData = Icons.medical_services;
                      break;
                    case 'education':
                      iconData = Icons.school;
                      break;
                  }
                }
              }

              return Dismissible(
                key: Key(tx.id),
                background: Container(
                  color: AppTheme.errorColor,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (dir) => _showConfirmDialog(context),
                onDismissed: (_) {
                  if (tx.isExpense) {
                    ref.read(expenseProvider.notifier).deleteExpense(tx.originalId);
                  } else {
                    ref.read(incomeProvider.notifier).deleteIncome(tx.originalId);
                  }
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.1),
                      child: Icon(iconData, color: iconColor),
                    ),
                    title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(tx.date), style: const TextStyle(fontSize: 11)),
                    trailing: Text(
                      '${tx.isExpense ? "-" : "+"}${NumberFormat.simpleCurrency(name: tx.currency).format(tx.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: tx.isExpense ? Colors.black87 : Colors.green[700],
                      ),
                    ),
                    onTap: () {
                      if (tx.isExpense) {
                        context.go('/expenses/edit', extra: tx.originalId);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Income details can only be deleted via swipe.')),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TxModel {
  final String id;
  final String title;
  final double amount;
  final String currency;
  final DateTime date;
  final bool isExpense;
  final int originalId;

  _TxModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    required this.isExpense,
    required this.originalId,
  });
}
