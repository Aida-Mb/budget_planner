import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../widgets/goal_progress_card.dart';
import '../../widgets/swipe_to_delete.dart';
import 'add_goal_sheet.dart';
import 'add_account_sheet.dart';
import 'contribute_goal_dialog.dart';
import 'transfer_sheet.dart';

/// Écran Accounts : liste des comptes (cash, carte, épargne)
/// et section objectifs d'épargne avec barres de progression.
class AccountsScreen extends StatelessWidget {
  AccountsScreen({super.key});

  final FirestoreService _firestoreService = FirestoreService();

  void _openSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLarge)),
      ),
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes comptes'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.pMedium),
        children: [
          // --- Section Comptes ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Comptes', style: AppStyles.h2),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _openTransferSheet(context),
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Transférer'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.textLight),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _openSheet(context, const AddAccountSheet()),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Nouveau'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.pSmall),
          _buildAccountsList(context),

          const SizedBox(height: AppSizes.pLarge),
          const Divider(),
          const SizedBox(height: AppSizes.pSmall),

          // --- Section Objectifs ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Objectifs d\'épargne', style: AppStyles.h2),
              TextButton.icon(
                onPressed: () => _openSheet(context, const AddGoalSheet()),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Ajouter'),
                style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.pSmall),
          _buildGoalsList(context),
          const SizedBox(height: AppSizes.pSmall),
          const Text(
            'Astuce : glisse une carte vers la gauche pour la supprimer.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  /// Le formulaire de transfert a besoin de la liste des comptes,
  /// donc on la récupère une fois via le Stream avant d'ouvrir le sheet.
  void _openTransferSheet(BuildContext context) {
    _firestoreService.watchAccounts().first.then((accounts) {
      if (accounts.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Il faut au moins 2 comptes pour transférer.')),
        );
        return;
      }
      if (!context.mounted) return;
      _openSheet(context, TransferSheet(accounts: accounts));
    });
  }

  Widget _buildAccountsList(BuildContext context) {
    return StreamBuilder<List<AccountModel>>(
      stream: _firestoreService.watchAccounts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final accounts = snapshot.data ?? [];
        if (accounts.isEmpty) {
          return _buildEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            message: 'Aucun compte pour le moment.\nCrée ton premier compte pour commencer.',
          );
        }
        return Column(
          children: accounts.asMap().entries.map((entry) {
            final index = entry.key;
            final acc = entry.value;
            final softColor =
            AppColors.softPalette[index % AppColors.softPalette.length];
            final iconData = AppCategories.accountTypes[acc.type] ??
                Icons.account_balance_wallet_outlined;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.pSmall),
              child: SwipeToDelete(
                dismissibleKey: ValueKey(acc.id),
                confirmTitle: 'Supprimer ce compte ?',
                confirmMessage:
                'Les transactions liées à "${acc.name}" resteront dans l\'historique mais ne seront plus rattachées à un compte actif.',
                onDelete: () => _firestoreService.deleteAccount(acc.id),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.pMedium),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: softColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSizes.pMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc.name,
                              style: AppStyles.body.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(acc.type,
                                style: AppStyles.body.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        '${acc.balance.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGoalsList(BuildContext context) {
    return StreamBuilder<List<GoalModel>>(
      stream: _firestoreService.watchGoals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final goals = snapshot.data ?? [];
        if (goals.isEmpty) {
          return _buildEmptyState(
            icon: Icons.flag_outlined,
            message: 'Aucun objectif.\nDéfinis un objectif pour suivre ton épargne.',
          );
        }
        const cardColors = [
          AppColors.primary,
          AppColors.secondary,
          AppColors.accent,
        ];
        return Column(
          children: goals.asMap().entries.map((entry) {
            final index = entry.key;
            final goal = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.pSmall),
              child: SwipeToDelete(
                dismissibleKey: ValueKey(goal.id),
                confirmTitle: 'Supprimer cet objectif ?',
                confirmMessage:
                'La progression épargnée sur "${goal.title}" sera perdue.',
                onDelete: () => _firestoreService.deleteGoal(goal.id),
                child: GoalProgressCard(
                  goal: goal,
                  color: cardColors[index % cardColors.length],
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => ContributeGoalDialog(goal: goal),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textLight),
          const SizedBox(height: AppSizes.pSmall),
          Text(message, textAlign: TextAlign.center, style: AppStyles.body),
        ],
      ),
    );
  }
}
