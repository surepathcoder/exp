import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../utils/currency_converter.dart';
import '../../theme/app_theme.dart';

class TrendLineChart extends ConsumerStatefulWidget {
  const TrendLineChart({super.key});

  @override
  ConsumerState<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends ConsumerState<TrendLineChart> {
  bool _isWeekly = false;

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider).expenses;

    // Prepare data
    final dataPoints = _prepareDataPoints(expenses);
    final spots = dataPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList();

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
                  'Expense Trend',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildToggleButton(label: 'Daily', active: !_isWeekly, onTap: () => setState(() => _isWeekly = false)),
                      _buildToggleButton(label: 'Weekly', active: _isWeekly, onTap: () => setState(() => _isWeekly = true)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: spots.isEmpty
                  ? const Center(child: Text('No recent transaction data'))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey[200]!, strokeWidth: 1, dashArray: [5, 5]),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final idx = val.toInt();
                                if (idx < 0 || idx >= dataPoints.length) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    dataPoints[idx].label,
                                    style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                              reservedSize: 22,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: AppTheme.primaryColor.withOpacity(0.9),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((touchedSpot) {
                                return LineTooltipItem(
                                  '\$${touchedSpot.y.toStringAsFixed(2)}',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppTheme.primaryColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryColor.withOpacity(0.3), AppTheme.primaryColor.withOpacity(0.0)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? AppTheme.primaryColor : Colors.grey[600]),
        ),
      ),
    );
  }

  List<ChartDataPoint> _prepareDataPoints(List<dynamic> expenses) {
    final now = DateTime.now();
    if (!_isWeekly) {
      // Last 7 Days
      return List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        double dailySum = 0;
        for (var exp in expenses) {
          if (exp.date.year == day.year && exp.date.month == day.month && exp.date.day == day.day) {
            dailySum += CurrencyConverter.convertToUsd(exp.amount, exp.currency);
          }
        }
        return ChartDataPoint(DateFormat('E').format(day), dailySum);
      });
    } else {
      // Last 4 Weeks
      return List.generate(4, (i) {
        final startOfWeek = now.subtract(Duration(days: (3 - i) * 7 + now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        double weeklySum = 0;
        for (var exp in expenses) {
          if (exp.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && exp.date.isBefore(endOfWeek.add(const Duration(seconds: 1)))) {
            weeklySum += CurrencyConverter.convertToUsd(exp.amount, exp.currency);
          }
        }
        return ChartDataPoint('W${i + 1}', weeklySum);
      });
    }
  }
}

class ChartDataPoint {
  final String label;
  final double amount;
  ChartDataPoint(this.label, this.amount);
}
