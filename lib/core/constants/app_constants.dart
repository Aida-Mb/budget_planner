import 'package:flutter/material.dart';

/// Palette de couleurs centralisée de l'application.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF5B4FE5);
  static const Color secondary = Color(0xFFFF9500);
  static const Color accent = Color(0xFFFFC300);


  static const List<Color> primaryGradient = [
    Color(0xFF6C5DFF),
    Color(0xFF5B4FE5),
  ];


  static const Color income = Color(0xFF00C48C);
  static const Color expense = Color(0xFFFF5252);


  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Colors.white;


  static const Color textDark = Color(0xFF1E2233);
  static const Color textLight = Color(0xFF8A8FA3);


  static const Color success = Color(0xFF00C48C);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFA800);


  static const List<Color> softPalette = [
    Color(0xFFE4E9FF),
    Color(0xFFEDE4FF),
    Color(0xFFFFE9D6),
    Color(0xFFDFF7EA),
    Color(0xFFFFE1E1),
  ];
}

class AppSizes {
  AppSizes._();

  static const double pSmall = 8.0;
  static const double pMedium = 16.0;
  static const double pLarge = 24.0;

  static const double radiusSmall = 10.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
}


class AppStyles {
  AppStyles._();

  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
  );

  static const TextStyle amountPositive = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.income,
  );

  static const TextStyle amountNegative = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.expense,
  );
}


class AppCategories {
  AppCategories._();

  static const List<String> expenseCategories = [
    'Alimentation',
    'Transport',
    'Logement',
    'Loisirs',
    'Santé',
    'Éducation',
    'Autres',
  ];

  static const List<String> incomeCategories = [
    'Salaire',
    'Bourse',
    'Cadeau',
    'Freelance',
    'Autres',
  ];


  static const Map<String, IconData> accountTypes = {
    'Cash': Icons.payments_outlined,
    'Carte bancaire': Icons.credit_card,
    'Épargne': Icons.savings_outlined,
  };
}
