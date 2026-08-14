import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import '../navigation/main_navigation.dart';

/// Point d'entrée après le splash Firebase : vérifie si l'utilisateur
/// a déjà vu l'onboarding. Si oui, va direct à l'app. Sinon, montre
/// les slides de présentation.
class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({super.key});

  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_seen') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasSeenOnboarding = snapshot.data ?? false;
        return hasSeenOnboarding
            ? const MainNavigation()
            : const OnboardingScreen();
      },
    );
  }
}
