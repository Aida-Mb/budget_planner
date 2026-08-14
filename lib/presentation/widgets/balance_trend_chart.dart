import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/transaction_model.dart';

/// Courbe de tendance du solde total sur les 7 derniers jours.
///
/// On ne stocke pas d'historique de solde en base — seulement le solde
/// ACTUEL de chaque compte. On reconstruit donc le solde passé en
/// remontant dans le temps : solde à la fin du jour D = solde actuel -
/// (somme des transactions survenues APRÈS ce jour D). Ça fonctionne car
/// les transferts entre comptes n'affectent pas le solde total (l'argent
/// change de compte mais pas de "poche"), seules les transactions
/// (revenu/dépense) le font.
class BalanceTrendChart extends StatelessWidget {
  final double currentTotalBalance;
  final List<TransactionModel> transactions;

  const BalanceTrendChart({
    super.key,
    required this.currentTotalBalance,
    required this.transactions,
  });

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<_BalancePoint> _computeTrend() {
    final today = _dayOnly(DateTime.now());
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    return days.map((day) {
      // Toutes les transactions survenues STRICTEMENT APRÈS ce jour
      final laterTransactionsSum = transactions
          .where((tx) => _dayOnly(tx.date).isAfter(day))
          .fold<double>(0, (sum, tx) => sum + tx.signedAmount);

      final balanceAtDay = currentTotalBalance - laterTransactionsSum;
      return _BalancePoint(date: day, balance: balanceAtDay);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final points = _computeTrend();
    final currencyFormat =
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    final minY = points.map((p) => p.balance).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.balance).reduce((a, b) => a > b ? a : b);
    // Marge de 10% en haut/bas pour que la courbe ne touche pas les bords
    final padding = ((maxY - minY).abs() * 0.15).clamp(1000, double.infinity);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Évolution du solde',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight)),
              Text(
                currencyFormat.format(points.last.balance),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.pMedium),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: minY - padding,
                maxY: maxY + padding,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
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
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        const dayLabels = [
                          'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'
                        ];
                        final weekday = points[index].date.weekday;
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
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((spot) {
                      return LineTooltipItem(
                        currencyFormat.format(spot.y),
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      points.length,
                          (i) => FlSpot(i.toDouble(), points[i].balance),
                    ),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalancePoint {
  final DateTime date;
  final double balance;

  _BalancePoint({required this.date, required this.balance});
}
