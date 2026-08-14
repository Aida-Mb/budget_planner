import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/transaction_model.dart';

/// Camembert des dépenses par catégorie pour le mois en cours.
/// Reçoit directement la liste des transactions (déjà filtrée par
/// mois côté écran appelant) pour rester un widget "bête" et réutilisable.
class ExpensePieChart extends StatefulWidget {
  final List<TransactionModel> transactions;

  const ExpensePieChart({super.key, required this.transactions});

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int _touchedIndex = -1;

  // Palette cyclique pour les parts du camembert (cohérente avec
  // le reste du design system).
  static const List<Color> _sliceColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.income,
    AppColors.expense,
    Color(0xFF64B5F6),
    Color(0xFFBA68C8),
  ];

  Map<String, double> get _totalsByCategory {
    final Map<String, double> totals = {};
    for (final tx in widget.transactions) {
      if (tx.type != TransactionType.expense) continue;
      totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totalsByCategory;

    if (totals.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: const Text(
          'Aucune dépense ce mois-ci.',
          style: AppStyles.body,
        ),
      );
    }

    final total = totals.values.fold<double>(0, (a, b) => a + b);
    final entries = totals.entries.toList();
    final currencyFormat =
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

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
        children: [
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex =
                                response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: List.generate(entries.length, (index) {
                        final isTouched = index == _touchedIndex;
                        final entry = entries[index];
                        final percentage = (entry.value / total) * 100;
                        return PieChartSectionData(
                          color: _sliceColors[index % _sliceColors.length],
                          value: entry.value,
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: isTouched ? 65 : 55,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(entries.length, (index) {
                      final entry = entries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color:
                                _sliceColors[index % _sliceColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: AppSizes.pLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total dépensé', style: AppStyles.body),
              Text(
                currencyFormat.format(total),
                style: AppStyles.amountNegative,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
