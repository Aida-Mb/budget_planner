import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/transaction_model.dart';

/// Diagramme en barres comparant revenus et dépenses jour par jour, sur les 7 derniers jours.
class WeeklyBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const WeeklyBarChart({super.key, required this.transactions});

  /// Regroupe les transactions des 7 derniers jours par jour, en séparant le total des revenus et des dépenses.
  List<_DayTotals> _computeDailyTotals() {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      return date;
    });

    return days.map((day) {
      final dayTransactions = transactions.where((tx) =>
      tx.date.year == day.year &&
          tx.date.month == day.month &&
          tx.date.day == day.day);

      final income = dayTransactions
          .where((tx) => tx.type == TransactionType.income)
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      final expense = dayTransactions
          .where((tx) => tx.type == TransactionType.expense)
          .fold<double>(0, (sum, tx) => sum + tx.amount);

      return _DayTotals(date: day, income: income, expense: expense);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dailyTotals = _computeDailyTotals();
    final maxValue = dailyTotals
        .expand((d) => [d.income, d.expense])
        .fold<double>(0, (max, v) => v > max ? v : max);

    // Si aucune transaction sur les 7 derniers jours, on affiche un
    // état vide plutôt qu'un graphique plat à 0.
    if (maxValue == 0) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: const Text(
          'Aucune activité sur les 7 derniers jours.',
          style: AppStyles.body,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.pMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLegendDot(AppColors.income, 'Revenus'),
              const SizedBox(width: 16),
              _buildLegendDot(AppColors.expense, 'Dépenses'),
            ],
          ),
          const SizedBox(height: AppSizes.pMedium),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxValue * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dailyTotals.length) {
                          return const SizedBox.shrink();
                        }
                        // On évite DateFormat('E', 'fr_FR') ici : il faut
                        // initializeDateFormatting() dans main() sinon ça
                        // plante. Une liste simple suffit pour 3 lettres.
                        const dayLabels = [
                          'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'
                        ];
                        final weekday = dailyTotals[index].date.weekday; // 1-7
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dayLabels[weekday - 1],
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textLight),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(dailyTotals.length, (index) {
                  final day = dailyTotals[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: day.income,
                        color: AppColors.income,
                        width: 7,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      BarChartRodData(
                        toY: day.expense,
                        color: AppColors.expense,
                        width: 7,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
      ],
    );
  }
}

class _DayTotals {
  final DateTime date;
  final double income;
  final double expense;

  _DayTotals({required this.date, required this.income, required this.expense});
}