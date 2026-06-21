import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/modules/home/presentation/screen/category_wise_transactions.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expensetrackify/constants/colors.dart';

class CategoryPieChart extends StatelessWidget {
  final List<TransactionWithDetails> transactions;
  const CategoryPieChart({required this.transactions, super.key});

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _categoryTotals(transactions);
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final colors = [
      AppColors.deepPurpleColor,
      Colors.blueAccent,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.green,
      Colors.amber,
      Colors.redAccent,
    ];
    final entries = categoryTotals.entries.toList();
    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: List.generate(entries.length, (i) {
                final entry = entries[i];
                final percent = total == 0 ? 0 : (entry.value / total * 100);
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: entry.value,
                  title: percent < 8 ? '' : '${percent.toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (event is FlTapUpEvent &&
                      pieTouchResponse != null &&
                      pieTouchResponse.touchedSection != null) {
                    final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    final touchedEntry = entries[touchedIndex];
                    debugPrint('Touched: ${touchedEntry.key} with value ${touchedEntry.value}');
                    final filteredTransactions = transactions.where((tx) {
                      return tx.category?.name == touchedEntry.key;
                    }).toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CategoryWiseTransactions(
                              category: touchedEntry.key,
                              transactions: filteredTransactions,
                            ),
                      ),
                    );
                  }
                },
              ),

            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: List.generate(entries.length, (i) {
            final entry = entries[i];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.key,
                  style: TextStyles.blackSemiBold12.copyWith(
                    color: AppColors.deepPurpleColor,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

Map<String, double> _categoryTotals(List<TransactionWithDetails> transactions) {
  final Map<String, double> totals = {};
  for (final tx in transactions) {
    final categoryName = tx.category?.name ?? 'Unknown';
    totals[categoryName] = (totals[categoryName] ?? 0) + tx.transaction.amount;
  }
  return totals;
}