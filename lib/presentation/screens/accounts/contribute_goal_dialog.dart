import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

/// Dialog compact pour ajouter une contribution (épargner un montant
/// de plus) à un objectif existant.
class ContributeGoalDialog extends StatefulWidget {
  final GoalModel goal;

  const ContributeGoalDialog({super.key, required this.goal});

  @override
  State<ContributeGoalDialog> createState() => _ContributeGoalDialogState();
}

class _ContributeGoalDialogState extends State<ContributeGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _firestoreService.contributeToGoal(
        widget.goal.id,
        double.parse(_amountController.text.trim()),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.goal.targetAmount - widget.goal.currentAmount;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Épargner pour', style: AppStyles.body),
              Text(widget.goal.title, style: AppStyles.h2),
              const SizedBox(height: 4),
              Text(
                'Il reste ${remaining.toStringAsFixed(0)} FCFA pour atteindre l\'objectif.',
                style: AppStyles.body.copyWith(fontSize: 13),
              ),
              const SizedBox(height: AppSizes.pMedium),
              CustomInput(
                label: 'Montant à ajouter (FCFA)',
                hint: 'ex : 20000',
                prefixIcon: Icons.add_circle_outline,
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le montant est requis';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.pLarge),
              CustomButton(
                text: 'Ajouter',
                isLoading: _isSaving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
