import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/reports_provider.dart';
import '../../theme/app_theme.dart';

class ReportsPreviewPanel extends ConsumerWidget {
  const ReportsPreviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsProvider);
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading) {
      return const Card(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.previewData == null) {
      return const Card(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('No preview data available.')),
        ),
      );
    }

    final data = state.previewData!;
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final counts = data['counts'] as Map<String, dynamic>? ?? {};
    final previewItems = data['preview'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Currency Cards Summary
        Text('Cash Flow Preview', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        const SizedBox(height: 8),
        _buildCurrencyCards(context, summary),
        const SizedBox(height: 16),

        // Counts Box
        _buildCountsGrid(context, counts),
        const SizedBox(height: 16),

        // Preview Items List
        Text('Preview (First 5 Transactions)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        const SizedBox(height: 8),
        if (previewItems.isEmpty)
          const Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No transactions fit the current filters.')),
            ),
          )
        else
          Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: previewItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = previewItems[index] as Map<String, dynamic>;
                return _buildPreviewListTile(context, item);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCurrencyCards(BuildContext context, Map<String, dynamic> summary) {
    final currencies = ["USD", "TZS", "KES"];
    final list = <Widget>[];

    for (var curr in currencies) {
      final metrics = summary[curr] as Map<String, dynamic>?;
      if (metrics == null) continue;
      
      final inflow = (metrics['inflow'] as num?)?.toDouble() ?? 0.0;
      final outflow = (metrics['outflow'] as num?)?.toDouble() ?? 0.0;
      final net = (metrics['net'] as num?)?.toDouble() ?? 0.0;

      if (inflow == 0.0 && outflow == 0.0) continue;

      final format = NumberFormat.currency(symbol: curr == 'USD' ? '\$' : '$curr ', decimalDigits: curr == 'USD' ? 2 : 0);

      list.add(
        Card(
          color: Colors.grey.shade50,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(curr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                    Text(format.format(net), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: net >= 0 ? Colors.green : Colors.red)),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Inflow: ${format.format(inflow)}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                    Text('Outflow: ${format.format(outflow)}', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return const Card(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No cash flows for this period.')),
        ),
      );
    }

    return Column(children: list);
  }

  Widget _buildCountsGrid(BuildContext context, Map<String, dynamic> counts) {
    Widget buildCountItem(String label, int value, IconData icon, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        buildCountItem('Incomes', counts['incomes'] ?? 0, Icons.arrow_downward, Colors.green),
        const SizedBox(width: 8),
        buildCountItem('Expenses', counts['expenses'] ?? 0, Icons.arrow_upward, Colors.redAccent),
        const SizedBox(width: 8),
        buildCountItem('Transfers', counts['transfers'] ?? 0, Icons.swap_horiz, Colors.blue),
      ],
    );
  }

  Widget _buildPreviewListTile(BuildContext context, Map<String, dynamic> item) {
    final type = item['type'] as String;
    final dateStr = item['date'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : null;
    final formattedDate = date != null ? DateFormat('MMM dd, yyyy').format(date) : '';
    
    IconData icon;
    Color iconColor;
    if (type == 'income') {
      icon = Icons.arrow_downward;
      iconColor = Colors.green;
    } else if (type == 'expense') {
      icon = Icons.arrow_upward;
      iconColor = Colors.redAccent;
    } else {
      icon = Icons.swap_horiz;
      iconColor = Colors.blue;
    }

    final category = item['category_source'] as String;
    final details = item['details'] as String;
    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
    final currency = item['currency'] as String;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text('$amount $currency', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (details.isNotEmpty) ...[
            Text(details, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
          ],
          Text('$formattedDate • ${item['user']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
