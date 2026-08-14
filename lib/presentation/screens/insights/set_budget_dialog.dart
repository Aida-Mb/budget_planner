import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/firestore_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

/// Dialog compact pour définir la limite budgétaire mensuelle
/// d'une catégorie donnée.
class SetBudgetDialog extends StatefulWidget {
  final String category;
  final double? currentLimit;

  const SetBudgetDialog({
    super.key,
    required this.category,
    this.currentLimit,
  });

  @override
  State<SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends State<SetBudgetDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentLimit != null
          ? widget.currentLimit!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _firestoreService.setBudgetLimit(
        widget.category,
        double.parse(_controller.text.trim()),
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
              Text('Budget · ${widget.category}', style: AppStyles.h2),
              const SizedBox(height: AppSizes.pMedium),
              CustomInput(
                label: 'Limite mensuelle (FCFA)',
                hint: 'ex : 100000',
                prefixIcon: Icons.pie_chart_outline,
                controller: _controller,
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
                text: 'Enregistrer',
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
