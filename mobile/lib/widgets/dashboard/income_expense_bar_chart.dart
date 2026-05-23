import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../utils/currency_converter.dart';
import '../../theme/app_theme.dart';

class IncomeExpenseBarChart extends ConsumerWidget {
  const IncomeExpenseBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseProvider).expenses;
    final incomes = ref.watch(incomeProvider).incomes;

    final now = DateTime.now();
    // Build list of last 6 months (ordered from 5 months ago to this month)
    final months = List.generate(6, (i) {
      return DateTime(now.year, now.month - (5 - i), 1);
    });

    final List<double> monthlyIncomes = List.filled(6, 0.0);
    final List<double> monthlyExpenses = List.filled(6, 0.0);

    for (var inc in incomes) {
      final usd = CurrencyConverter.convertToUsd(inc.amount, inc.currency);
      for (int i = 0; i < 6; i++) {
        final m = months[i];
        if (inc.date.year == m.year && inc.date.month == m.month) {
          monthlyIncomes[i] += usd;
        }
      }
    }

    for (var exp in expenses) {
      final usd = CurrencyConverter.convertToUsd(exp.amount, exp.currency);
      for (int i = 0; i < 6; i++) {
        final m = months[i];
        if (exp.date.year == m.year && exp.date.month == m.month) {
          monthlyExpenses[i] += usd;
        }
      }
    }

    double maxVal = 100.0;
    for (int i = 0; i < 6; i++) {
      maxVal = math.max(maxVal, math.max(monthlyIncomes[i], monthlyExpenses[i]));
    }
    // Add 15% headroom
    maxVal = maxVal * 1.15;

    final barGroups = List.generate(6, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: monthlyIncomes[i],
            color: Colors.green[400],
            width: 8,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          BarChartRodData(
            toY: monthlyExpenses[i],
            color: AppTheme.primaryColor.withOpacity(0.9),
            width: 8,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Income vs Expense',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Row(
                  children: [
                    _buildLegendItem(Colors.green[400]!, 'Income'),
                    const SizedBox(width: 12),
                    _buildLegendItem(AppTheme.primaryColor, 'Expense'),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxVal,
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey[200]!, strokeWidth: 1, dashArray: [5, 5]),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox();
                          String label = value >= 1000 ? '\$${(value / 1000).toStringAsFixed(0)}k' : '\$${value.toStringAsFixed(0)}';
                          return Text(
                            label,
                            style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= 6) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MMM').format(months[idx]),
                              style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.blueGrey[800]!,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '\$${rod.toY.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
