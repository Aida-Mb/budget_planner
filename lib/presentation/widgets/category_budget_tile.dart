import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';

class CategoryBudgetTile extends StatelessWidget {
  final String category;
  final double spent;
  final double? limit; // null si aucune limite définie pour cette catégorie
  final VoidCallback onSetBudget;

  const CategoryBudgetTile({
    super.key,
    required this.category,
    required this.spent,
    required this.onSetBudget,
    this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    final hasLimit = limit != null && limit! > 0;
    final progress = hasLimit ? (spent / limit!).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = hasLimit && spent > limit!;
    final progressColor = isOverBudget
        ? AppColors.error
        : (progress > 0.8 ? AppColors.warning : AppColors.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.pSmall),
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
              Text(
                category,
                style: AppStyles.body.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasLimit)
                GestureDetector(
                  onTap: onSetBudget,
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.textLight),
                )
              else
                TextButton(
                  onPressed: onSetBudget,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Définir un budget',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.pSmall),
          if (hasLimit) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: progressColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: AppSizes.pSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currencyFormat.format(spent)} dépensé',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverBudget ? AppColors.error : AppColors.textLight,
                    fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  isOverBudget
                      ? 'Dépassé de ${currencyFormat.format(spent - limit!)}'
                      : '${currencyFormat.format(limit! - spent)} restant',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverBudget ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else
            Text(
              '${currencyFormat.format(spent)} dépensé ce mois-ci',
              style: AppStyles.body.copyWith(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
