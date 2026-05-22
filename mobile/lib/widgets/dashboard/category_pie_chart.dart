import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../utils/currency_converter.dart';
import '../../utils/color_parser.dart';

class CategoryPieChart extends ConsumerStatefulWidget {
  const CategoryPieChart({super.key});

  @override
  ConsumerState<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends ConsumerState<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(categoryProvider.notifier).fetchCategories(all: false);
    });
  }

  Color _getCategoryColor(String name, CategoryState categoryState) {
    final cat = categoryState.categoriesByName[name];
    if (cat != null) {
      return ColorParser.fromHex(cat.color);
    }
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    final hue = (hash * 137.5) % 360;
    return HSLColor.fromAHSL(1.0, hue, 0.65, 0.5).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider).expenses;
    final categoryState = ref.watch(categoryProvider);
    if (expenses.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SizedBox(
            height: 200,
            child: Center(child: Text('No expense data available')),
          ),
        ),
      );
    }

    final Map<String, double> categorySums = {};
    double totalSum = 0;
    for (var exp in expenses) {
      final usd = CurrencyConverter.convertToUsd(exp.amount, exp.currency);
      categorySums[exp.category] = (categorySums[exp.category] ?? 0) + usd;
      totalSum += usd;
    }

    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Limit to top 4 and group others
    final List<MapEntry<String, double>> segments = [];
    double otherSum = 0;
    for (int i = 0; i < sortedCategories.length; i++) {
      if (i < 4) {
        segments.add(sortedCategories[i]);
      } else {
        otherSum += sortedCategories[i].value;
      }
    }
    if (otherSum > 0) {
      segments.add(MapEntry('Other', otherSum));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expenses by Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
                        sections: List.generate(segments.length, (i) {
                          final isTouched = i == _touchedIndex;
                          final double fontSize = isTouched ? 16.0 : 12.0;
                          final double radius = isTouched ? 55.0 : 45.0;
                          final segment = segments[i];
                          final percentage = totalSum > 0 ? (segment.value / totalSum) * 100 : 0.0;

                          return PieChartSectionData(
                            color: _getCategoryColor(segment.key, categoryState),
                            value: segment.value,
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: radius,
                            titleStyle: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: segments.map((entry) {
                      final color = _getCategoryColor(entry.key, categoryState);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
