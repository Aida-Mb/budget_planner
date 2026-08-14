import 'package:flutter/material.dart';

/// Palette de couleurs centralisée de l'application.
/// Direction visuelle : "clair & vif" — fond clair, couleurs saturées
/// (indigo + orange), cartes arrondies avec ombres légères.
/// Règle d'or : ne JAMAIS écrire Colors.xxx en dur dans les écrans.
class AppColors {
  AppColors._(); // Constructeur privé : empêche l'instanciation

  // Couleurs principales — plus vives et saturées qu'avant
  static const Color primary = Color(0xFF5B4FE5); // Indigo vif
  static const Color secondary = Color(0xFFFF9500); // Orange vif
  static const Color accent = Color(0xFFFFC300); // Jaune vif (CTA ponctuels)

  // Dégradé utilisé pour les cartes "hero" (solde, budget...)
  static const List<Color> primaryGradient = [
    Color(0xFF6C5DFF),
    Color(0xFF5B4FE5),
  ];

  // Couleurs sémantiques (revenu / dépense)
  static const Color income = Color(0xFF00C48C);
  static const Color expense = Color(0xFFFF5252);

  // Couleurs de fond
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Colors.white;

  // Couleurs typographiques
  static const Color textDark = Color(0xFF1E2233);
  static const Color textLight = Color(0xFF8A8FA3);

  // Couleurs de statut (alignées sur income/expense pour la cohérence)
  static const Color success = Color(0xFF00C48C);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFA800);

  // Palette douce utilisée pour les icônes de catégories/comptes
  // (cercles pastel derrière les icônes, façon image de référence).
  static const List<Color> softPalette = [
    Color(0xFFE4E9FF), // bleu pastel
    Color(0xFFEDE4FF), // violet pastel
    Color(0xFFFFE9D6), // orange pastel
    Color(0xFFDFF7EA), // vert pastel
    Color(0xFFFFE1E1), // rose pastel
  ];
}

/// Espacements et rayons de bordure centralisés.
class AppSizes {
  AppSizes._();

  static const double pSmall = 8.0;
  static const double pMedium = 16.0;
  static const double pLarge = 24.0;

  static const double radiusSmall = 10.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
}

/// Styles de texte réutilisables.
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

/// Catégories prédéfinies pour les transactions (utilisées dans
/// le formulaire d'ajout et les graphiques Insights).
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

  /// Type de compte : nom affiché associé à une icône, pour le
  /// sélecteur visuel dans le formulaire de création de compte.
  static const Map<String, IconData> accountTypes = {
    'Cash': Icons.payments_outlined,
    'Carte bancaire': Icons.credit_card,
    'Épargne': Icons.savings_outlined,
  };
}
