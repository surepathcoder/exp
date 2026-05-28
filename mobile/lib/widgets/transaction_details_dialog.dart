import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/transfer.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/transfer_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'add_income_dialog.dart';
import 'add_transfer_dialog.dart';

class TransactionDetailsDialog extends ConsumerWidget {
  final String txType; // 'expense', 'income', 'transfer'
  final int originalId;

  const TransactionDetailsDialog({
    super.key,
    required this.txType,
    required this.originalId,
  });

  static void show(BuildContext context, String txType, int originalId) {
    showDialog(
      context: context,
      builder: (context) => TransactionDetailsDialog(
        txType: txType,
        originalId: originalId,
      ),
    );
  }

  Future<bool?> _showConfirmDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction permanently?'),
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
  }

  void _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await _showConfirmDeleteDialog(context);
    if (confirm == true) {
      try {
        if (txType == 'expense') {
          await ref.read(expenseProvider.notifier).deleteExpense(originalId);
        } else if (txType == 'income') {
          await ref.read(incomeProvider.notifier).deleteIncome(originalId);
        } else if (txType == 'transfer') {
          await ref.read(transferProvider.notifier).deleteTransfer(originalId);
        }
        await ref.read(dashboardProvider.notifier).fetchDashboardData();

        if (context.mounted) {
          Navigator.pop(context); // Close details dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting transaction: $e'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }

  void _handleEdit(BuildContext context, WidgetRef ref, dynamic txData) {
    Navigator.pop(context); // Close details dialog first

    if (txType == 'expense') {
      context.go('/expenses/edit', extra: originalId);
    } else if (txType == 'income') {
      showDialog(
        context: context,
        builder: (context) => AddIncomeDialog(income: txData as Income),
      );
    } else if (txType == 'transfer') {
      showDialog(
        context: context,
        builder: (context) => AddTransferDialog(transfer: txData as Transfer),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletProvider).wallets;
    final user = ref.watch(authProvider).user;
    final isAdmin = user != null && user.role.name != 'user';

    dynamic txData;
    String title = '';
    Color themeColor = AppTheme.primaryColor;
    IconData headerIcon = Icons.payment;

    if (txType == 'expense') {
      final expenses = ref.watch(expenseProvider).expenses;
      txData = expenses.firstWhere((e) => e.id == originalId, orElse: () => Expense(amount: 0, currency: 'USD', category: 'N/A', date: DateTime.now()));
      title = 'Expense Details';
      themeColor = AppTheme.primaryColor;
      headerIcon = Icons.arrow_downward;
    } else if (txType == 'income') {
      final incomes = ref.watch(incomeProvider).incomes;
      txData = incomes.firstWhere((i) => i.id == originalId, orElse: () => Income(amount: 0, currency: 'USD', source: 'N/A', date: DateTime.now()));
      title = 'Income Details';
      themeColor = Colors.green;
      headerIcon = Icons.arrow_upward;
    } else if (txType == 'transfer') {
      final transfers = ref.watch(transferProvider).transfers;
      txData = transfers.firstWhere((t) => t.id == originalId, orElse: () => Transfer(amountFrom: 0, currencyFrom: 'USD', amountTo: 0, currencyTo: 'USD', date: DateTime.now()));
      title = 'Transfer Details';
      themeColor = Colors.blue;
      headerIcon = Icons.swap_horiz;
    }

    if (txData == null || txData.id == null) {
      return const AlertDialog(
        content: Text('Transaction details not found.'),
      );
    }

    final canEdit = txData.userId == user?.id || isAdmin;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(headerIcon, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Details Body
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount row
                    Center(
                      child: Column(
                        children: [
                          Text(
                            txType == 'transfer'
                                ? '${NumberFormat.simpleCurrency(name: txData.currencyFrom).format(txData.amountFrom)} -> ${NumberFormat.simpleCurrency(name: txData.currencyTo).format(txData.amountTo)}'
                                : NumberFormat.simpleCurrency(name: txData.currency).format(txData.amount),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: themeColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            txType == 'transfer'
                                ? '${txData.currencyFrom} to ${txData.currencyTo}'
                                : '${txData.currency}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Detail items
                    _buildDetailRow(
                      context, 
                      'Date', 
                      DateFormat('MMMM dd, yyyy  •  hh:mm a').format(txData.date.toLocal()),
                      Icons.calendar_today,
                    ),

                    if (txType == 'expense') ...[
                      _buildDetailRow(context, 'Category', txData.category, Icons.category),
                      _buildDetailRow(
                        context, 
                        'Wallet / Account', 
                        _getWalletName(wallets, txData.walletId),
                        Icons.account_balance_wallet,
                      ),
                      _buildDetailRow(context, 'Project', txData.project ?? 'No Project (Skip)', Icons.business_center),
                      if (txData.paymentMethod != null && txData.paymentMethod.isNotEmpty)
                        _buildDetailRow(context, 'Payment Method', txData.paymentMethod, Icons.payment),
                      if (txData.vendor != null && txData.vendor.isNotEmpty)
                        _buildDetailRow(context, 'Vendor', txData.vendor, Icons.store),
                      if (txData.location != null && txData.location.isNotEmpty)
                        _buildDetailRow(context, 'Location', txData.location, Icons.location_on),
                    ] else if (txType == 'income') ...[
                      _buildDetailRow(context, 'Source', txData.source, Icons.source),
                      _buildDetailRow(
                        context, 
                        'Deposited To', 
                        _getWalletName(wallets, txData.walletId),
                        Icons.account_balance_wallet,
                      ),
                      _buildDetailRow(context, 'Project', txData.project ?? 'No Project (Skip)', Icons.business_center),
                    ] else if (txType == 'transfer') ...[
                      _buildDetailRow(
                        context, 
                        'From Wallet', 
                        _getWalletName(wallets, txData.walletFromId),
                        Icons.outbox,
                      ),
                      _buildDetailRow(
                        context, 
                        'To Wallet', 
                        _getWalletName(wallets, txData.walletToId),
                        Icons.inbox,
                      ),
                      _buildDetailRow(context, 'Project', txData.project ?? 'No Project (Skip)', Icons.business_center),
                    ],

                    if (txData.note != null && txData.note.isNotEmpty)
                      _buildDetailRow(context, 'Note / Description', txData.note, Icons.notes),

                    // Receipt Preview for Expense
                    if (txType == 'expense' && txData.photoUrl != null && txData.photoUrl.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Receipt Photo',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _showReceiptViewer(context, txData.photoUrl),
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Image.network(
                              txData.photoUrl.startsWith('http')
                                  ? txData.photoUrl
                                  : '${Constants.baseUrl}/static/${txData.photoUrl}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                );
                              },
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (canEdit) ...[
                          TextButton.icon(
                            onPressed: () => _handleDelete(context, ref),
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            label: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _handleEdit(context, ref, txData),
                            icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                            label: const Text('EDIT'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ] else
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CLOSE'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWalletName(List<dynamic> wallets, int? walletId) {
    if (walletId == null) return 'Generic Balance';
    final wallet = wallets.firstWhere((w) => w.id == walletId, orElse: () => null);
    return wallet != null ? '${wallet.name} (${wallet.currency})' : 'Unknown Wallet';
  }

  void _showReceiptViewer(BuildContext context, String url) {
    final fullUrl = url.startsWith('http') ? url : '${Constants.baseUrl}/static/$url';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                fullUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(40),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, size: 60, color: Colors.red),
                        SizedBox(height: 12),
                        Text('Failed to load image', style: TextStyle(color: Colors.black87)),
                      ],
                    ),
                  );
                },
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
