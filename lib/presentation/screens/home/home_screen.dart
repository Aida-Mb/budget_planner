import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../widgets/weekly_bar_chart.dart';
import '../../widgets/balance_trend_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Un seul service, injecté ici. On pourrait le passer en paramètre
  // du widget si on veut faciliter les tests plus tard.
  final FirestoreService _firestoreService = FirestoreService();

  final NumberFormat _currencyFormat =
  NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Budget'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      // StreamBuilder n°1 : écoute les comptes pour calculer le solde total
      body: StreamBuilder<List<AccountModel>>(
        stream: _firestoreService.watchAccounts(),
        builder: (context, accountsSnapshot) {
          if (accountsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (accountsSnapshot.hasError) {
            return Center(child: Text('Erreur : ${accountsSnapshot.error}'));
          }

          final accounts = accountsSnapshot.data ?? [];
          final totalBalance =
          accounts.fold<double>(0, (sum, acc) => sum + acc.balance);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.pMedium),
            children: [
              _buildBalanceCard(totalBalance),
              const SizedBox(height: AppSizes.pLarge),
              // StreamBuilder n°2 : écoute les transactions (sert à la fois
              // au diagramme en barres et à la liste des dernières transactions)
              StreamBuilder<List<TransactionModel>>(
                stream: _firestoreService.watchTransactions(),
                builder: (context, txSnapshot) {
                  if (txSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (txSnapshot.hasError) {
                    return Text('Erreur : ${txSnapshot.error}');
                  }

                  final transactions = txSnapshot.data ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cette semaine', style: AppStyles.h2),
                      const SizedBox(height: AppSizes.pSmall),
                      WeeklyBarChart(transactions: transactions),
                      const SizedBox(height: AppSizes.pMedium),
                      BalanceTrendChart(
                        currentTotalBalance: totalBalance,
                        transactions: transactions,
                      ),
                      const SizedBox(height: AppSizes.pLarge),
                      Text('Transactions récentes', style: AppStyles.h2),
                      const SizedBox(height: AppSizes.pMedium),
                      if (transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Aucune transaction pour le moment.',
                              style: AppStyles.body,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.take(5).length,
                          separatorBuilder: (_, __) =>
                          const Divider(color: Colors.grey),
                          itemBuilder: (context, index) {
                            return _buildTransactionTile(
                                transactions.take(5).toList()[index]);
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double totalBalance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.pLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde total',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
    final isIncome = tx.type == TransactionType.income;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor:
        (isIncome ? AppColors.income : AppColors.expense).withOpacity(0.15),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIncome ? AppColors.income : AppColors.expense,
        ),
      ),
      title: Text(tx.category, style: AppStyles.body.copyWith(color: AppColors.textDark)),
      subtitle: Text(DateFormat('dd/MM/yyyy').format(tx.date)),
      trailing: Text(
        '${isIncome ? '+' : '-'}${_currencyFormat.format(tx.amount)}',
        style: isIncome ? AppStyles.amountPositive : AppStyles.amountNegative,
      ),
    );
  }
}
