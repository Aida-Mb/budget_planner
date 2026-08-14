import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../home/home_screen.dart';
import '../insights/insights_screen.dart';
import '../accounts/accounts_screen.dart';
import '../transactions/transactions_screen.dart';

/// Point d'entrée de la navigation : gère le changement entre
/// les 4 pages principales via une bottom navigation bar.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // On garde les écrans en mémoire (pas de rebuild complet à chaque
  // changement d'onglet).
  final List<Widget> _screens = [
    const HomeScreen(),
    InsightsScreen(),
    AccountsScreen(),
    TransactionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart), label: 'Insights'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Comptes'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Transactions'),
        ],
      ),
    );
  }
}
