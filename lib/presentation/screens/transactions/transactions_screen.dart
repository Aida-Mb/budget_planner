import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../widgets/swipe_to_delete.dart';
import 'add_transaction_screen.dart';

enum _PeriodFilter { today, week, month, all }

/// Écran Transactions : historique complet, filtrable par période,
/// avec suppression par swipe.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final NumberFormat _currencyFormat =
  NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  _PeriodFilter _selectedFilter = _PeriodFilter.all;
  String _searchQuery = '';

  void _openAddTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }

  void _openEditTransaction(TransactionModel tx) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(existingTransaction: tx),
      ),
    );
  }

  /// Filtre par texte : cherche dans la catégorie ET la note.
  List<TransactionModel> _applySearch(List<TransactionModel> transactions) {
    if (_searchQuery.trim().isEmpty) return transactions;
    final query = _searchQuery.trim().toLowerCase();
    return transactions.where((tx) {
      final inCategory = tx.category.toLowerCase().contains(query);
      final inNote = (tx.note ?? '').toLowerCase().contains(query);
      return inCategory || inNote;
    }).toList();
  }

  /// Filtre la liste de transactions selon la période choisie.
  List<TransactionModel> _applyFilter(List<TransactionModel> transactions) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case _PeriodFilter.today:
        return transactions
            .where((tx) =>
        tx.date.year == now.year &&
            tx.date.month == now.month &&
            tx.date.day == now.day)
            .toList();
      case _PeriodFilter.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        return transactions.where((tx) => tx.date.isAfter(weekAgo)).toList();
      case _PeriodFilter.month:
        return transactions
            .where((tx) =>
        tx.date.year == now.year && tx.date.month == now.month)
            .toList();
      case _PeriodFilter.all:
        return transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _firestoreService.watchTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final transactions =
                _applySearch(_applyFilter(snapshot.data ?? []));
                if (transactions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.pLarge),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 48, color: AppColors.textLight),
                          const SizedBox(height: AppSizes.pMedium),
                          const Text(
                            'Aucune transaction pour cette période.',
                            style: AppStyles.body,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pMedium),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSizes.pSmall),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return SwipeToDelete(
                      dismissibleKey: ValueKey(tx.id),
                      confirmTitle: 'Supprimer la transaction ?',
                      confirmMessage:
                      'Le solde du compte associé sera ajusté en conséquence.',
                      onDelete: () => _firestoreService.deleteTransaction(tx),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        onTap: () => _openEditTransaction(tx),
                        child: _buildTransactionTile(tx),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _openAddTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.pMedium, AppSizes.pMedium, AppSizes.pMedium, 0),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Rechercher (catégorie, note...)',
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final options = {
      _PeriodFilter.today: 'Aujourd\'hui',
      _PeriodFilter.week: '7 jours',
      _PeriodFilter.month: 'Ce mois',
      _PeriodFilter.all: 'Tout',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pMedium, vertical: AppSizes.pSmall),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.entries.map((entry) {
            final isSelected = _selectedFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedFilter = entry.key),
                selectedColor: AppColors.primary.withOpacity(0.15),
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
    final isIncome = tx.type == TransactionType.income;
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
            (isIncome ? AppColors.income : AppColors.expense).withOpacity(0.15),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? AppColors.income : AppColors.expense,
            ),
          ),
          const SizedBox(width: AppSizes.pMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.category,
                  style: AppStyles.body.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(tx.date),
                  style: AppStyles.body.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${_currencyFormat.format(tx.amount)}',
            style: isIncome ? AppStyles.amountPositive : AppStyles.amountNegative,
          ),
        ],
      ),
    );
  }
}

