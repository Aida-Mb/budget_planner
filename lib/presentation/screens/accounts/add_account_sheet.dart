import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/account_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

/// Bottom sheet permettant de créer un nouveau compte
/// (Cash, Carte bancaire, Épargne) avec un solde de départ.
class AddAccountSheet extends StatefulWidget {
  const AddAccountSheet({super.key});

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedType = AppCategories.accountTypes.keys.first;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final account = AccountModel(
        id: '',
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: double.parse(_balanceController.text.trim()),
      );
      await _firestoreService.addAccount(account);
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
            Text('Nouveau compte', style: AppStyles.h2),
            const SizedBox(height: AppSizes.pLarge),

            Text('Type de compte',
                style: AppStyles.body.copyWith(color: AppColors.textDark)),
            const SizedBox(height: AppSizes.pSmall),
            _buildTypeSelector(),
            const SizedBox(height: AppSizes.pMedium),

            CustomInput(
              label: 'Nom du compte',
              hint: 'ex : Compte principal',
              prefixIcon: Icons.edit_outlined,
              controller: _nameController,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Le nom est requis'
                  : null,
            ),
            const SizedBox(height: AppSizes.pMedium),

            CustomInput(
              label: 'Solde de départ (FCFA)',
              hint: 'ex : 100000',
              prefixIcon: Icons.account_balance_wallet_outlined,
              controller: _balanceController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le solde est requis (0 si vide)';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.pLarge),

            CustomButton(
              text: 'Créer le compte',
              isLoading: _isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  /// Rangée de "chips" visuels pour choisir le type de compte,
  Widget _buildTypeSelector() {
    final types = AppCategories.accountTypes.entries.toList();

    return Row(
      children: types.map((entry) {
        final isSelected = _selectedType == entry.key;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSizes.pSmall),
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade200,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      entry.value,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textLight,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.key,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
