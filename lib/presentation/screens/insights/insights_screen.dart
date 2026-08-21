import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../widgets/category_budget_tile.dart';
import '../../widgets/expense_pie_chart.dart';
import 'set_budget_dialog.dart';

/// Écran Insights : budget par catégorie
class InsightsScreen extends StatelessWidget {
  InsightsScreen({super.key});

  final FirestoreService _firestoreService = FirestoreService();

  void _openSetBudgetDialog(
      BuildContext context, String category, double? currentLimit) {
    showDialog(
      context: context,
      builder: (_) => SetBudgetDialog(
        category: category,
        currentLimit: currentLimit,
      ),
    );
  }

  /// Filtre les transactions pour ne garder que celles du mois en cours
  /// (utilisé à la fois par le camembert et par le calcul des budgets).
  List<TransactionModel> _transactionsThisMonth(
      List<TransactionModel> transactions) {
    final now = DateTime.now();
    return transactions
        .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
        .toList();
  }

  /// Calcule le total dépensé pour une catégorie sur le mois en cours.
  double _spentThisMonth(List<TransactionModel> transactions, String category) {
    final now = DateTime.now();
    return transactions
        .where((tx) =>
    tx.type == TransactionType.expense &&
        tx.category == category &&
        tx.date.year == now.year &&
        tx.date.month == now.month)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      // On combine deux Stream : les transactions (pour calculer les
      // dépenses par catégorie) et les budgets (pour les limites définies).
      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestoreService.watchTransactions(),
        builder: (context, txSnapshot) {
          if (txSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final transactions = txSnapshot.data ?? [];

          return StreamBuilder<List<BudgetModel>>(
            stream: _firestoreService.watchBudgets(),
            builder: (context, budgetSnapshot) {
              if (budgetSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final budgets = budgetSnapshot.data ?? [];
              final budgetMap = {
                for (final b in budgets) b.category: b.limitAmount,
              };

              return StreamBuilder<List<CategoryModel>>(
                stream: _firestoreService.watchCustomCategories(),
                builder: (context, categorySnapshot) {
                  final customExpenseCategories = (categorySnapshot.data ?? [])
                      .where((c) => c.type == 'expense')
                      .map((c) => c.name)
                      .toList();
                  final allExpenseCategories = [
                    ...AppCategories.expenseCategories,
                    ...customExpenseCategories,
                  ];

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSizes.pMedium),
                    children: [
                      Text('Répartition des dépenses', style: AppStyles.h2),
                      const SizedBox(height: AppSizes.pSmall),
                      ExpensePieChart(
                        transactions: _transactionsThisMonth(transactions),
                      ),
                      const SizedBox(height: AppSizes.pLarge),
                      Text('Budgets du mois', style: AppStyles.h2),
                      const SizedBox(height: 4),
                      Text(
                        'Suis tes dépenses par catégorie et fixe des limites.',
                        style: AppStyles.body,
                      ),
                      const SizedBox(height: AppSizes.pMedium),
                      ...allExpenseCategories.map((category) {
                        final spent = _spentThisMonth(transactions, category);
                        final limit = budgetMap[category];
                        return CategoryBudgetTile(
                          category: category,
                          spent: spent,
                          limit: limit,
                          onSetBudget: () => _openSetBudgetDialog(
                              context, category, limit),
                        );
                      }),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
