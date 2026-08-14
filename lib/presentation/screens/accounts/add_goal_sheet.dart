import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

/// Affiche un bottom sheet permettant de créer un nouvel objectif.
/// Appelée depuis AccountsScreen via showModalBottomSheet.
class AddGoalSheet extends StatefulWidget {
  const AddGoalSheet({super.key});

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final goal = GoalModel(
        id: '', // généré par Firestore lors de l'ajout
        title: _titleController.text.trim(),
        targetAmount: double.parse(_targetController.text.trim()),
        currentAmount: 0,
      );
      await _firestoreService.addGoal(goal);
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
    return Padding(
      // Remonte le formulaire au-dessus du clavier
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.pLarge,
        left: AppSizes.pLarge,
        right: AppSizes.pLarge,
        top: AppSizes.pLarge,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouvel objectif', style: AppStyles.h2),
            const SizedBox(height: AppSizes.pLarge),
            CustomInput(
              label: 'Nom de l\'objectif',
              hint: 'ex : Voyage à Dakar',
              prefixIcon: Icons.flag_outlined,
              controller: _titleController,
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'Le nom est requis'
                      : null,
            ),
            const SizedBox(height: AppSizes.pMedium),
            CustomInput(
              label: 'Montant cible (FCFA)',
              hint: 'ex : 500000',
              prefixIcon: Icons.savings_outlined,
              controller: _targetController,
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
              text: 'Créer l\'objectif',
              isLoading: _isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
