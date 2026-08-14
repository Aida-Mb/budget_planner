import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Calculatrice compacte permettant de calculer un montant
/// (ex : 1500 + 350 + 2000) directement dans le formulaire de
/// transaction, plutôt que de faire le calcul mentalement.
/// Retourne le résultat via Navigator.pop(result) — null si annulé.
class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _expression = '';
  String _display = '0';

  void _onKeyTap(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _expression = '';
          _display = '0';
          break;
        case '⌫':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
          _display = _expression.isEmpty ? '0' : _expression;
          break;
        case '=':
          _evaluate();
          break;
        default:
          _expression += key;
          _display = _expression;
      }
    });
  }

  /// Évaluation volontairement simple : ne gère que + et - en chaîne
  /// (largement suffisant pour additionner des dépenses rapidement,
  /// pas besoin d'un vrai parseur d'expressions pour ce cas d'usage).
  void _evaluate() {
    if (_expression.isEmpty) return;
    try {
      final tokens = _expression.split(RegExp(r'(?=[+-])'));
      double result = 0;
      for (final token in tokens) {
        result += double.parse(token);
      }
      _display = result.toStringAsFixed(
          result.truncateToDouble() == result ? 0 : 2);
      _expression = _display;
    } catch (_) {
      _display = 'Erreur';
      _expression = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const keys = [
      '7', '8', '9', 'C',
      '4', '5', '6', '⌫',
      '1', '2', '3', '+',
      '0', '.', '=', '-',
    ];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.pMedium),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              alignment: Alignment.centerRight,
              child: Text(
                _display,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.pMedium),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.3,
              children: keys.map((key) => _buildKey(key)).toList(),
            ),
            const SizedBox(height: AppSizes.pMedium),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
                onPressed: () {
                  // On évalue l'expression en cours avant de la renvoyer,
                  // au cas où l'utilisateur n'a pas appuyé sur "=" avant
                  // de cliquer (ex : "1500+200" tapé directement).
                  _evaluate();
                  final value = double.tryParse(_display);
                  Navigator.of(context).pop(value);
                },
                child: const Text('Utiliser ce montant'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String key) {
    final isOperator = ['+', '-', '=', 'C', '⌫'].contains(key);
    return Material(
      color: isOperator
          ? AppColors.primary.withOpacity(0.1)
          : AppColors.background,
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        onTap: () => _onKeyTap(key),
        child: Center(
          child: Text(
            key,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isOperator ? AppColors.primary : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
