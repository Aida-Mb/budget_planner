import 'package:flutter/material.dart';

/// Représente le contenu d'une slide d'onboarding.
/// Garder ça en dehors du widget permet d'ajouter/modifier des slides
/// sans toucher à la logique du PageView.
class OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;

  const OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
  });
}

const List<OnboardingSlide> onboardingSlides = [
  OnboardingSlide(
    icon: Icons.savings_rounded,
    title: 'Prends le contrôle\nde ton budget',
    description:
    'Suis tes dépenses et tes revenus au quotidien, simplement et visuellement.',
    gradientColors: [Color(0xFF6C5DFF), Color(0xFF5B4FE5)],
  ),
  OnboardingSlide(
    icon: Icons.account_balance_wallet_rounded,
    title: 'Gère tous\ntes comptes',
    description:
    'Cash, carte bancaire, épargne : visualise le solde de chaque compte séparément.',
    gradientColors: [Color(0xFF5B4FE5), Color(0xFFFF9500)],
  ),
  OnboardingSlide(
    icon: Icons.flag_rounded,
    title: 'Atteins tes\nobjectifs',
    description:
    'Définis des objectifs d\'épargne (voyage, achat...) et suis ta progression.',
    gradientColors: [Color(0xFFFF9500), Color(0xFFFFC300)],
  ),
];
