import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/account_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

/// Bottom sheet permettant de transférer un montant d'un compte
/// vers un autre (façon image de référence "Transfer funds").
class TransferSheet extends StatefulWidget {
  final List<AccountModel> accounts;

  const TransferSheet({super.key, required this.accounts});

  @override
  State<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<TransferSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String? _fromAccountId;
  String? _toAccountId;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromAccountId == null || _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis les deux comptes.')),
      );
      return;
    }
    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis deux comptes différents.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _firestoreService.transferBetweenAccounts(
        fromAccountId: _fromAccountId!,
        toAccountId: _toAccountId!,
        amount: double.parse(_amountController.text.trim()),
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
            Text('Transférer entre comptes', style: AppStyles.h2),
            const SizedBox(height: AppSizes.pLarge),

            Text('Depuis', style: AppStyles.body.copyWith(color: AppColors.textDark)),
            const SizedBox(height: 6),
            _buildAccountDropdown(
              value: _fromAccountId,
              onChanged: (value) => setState(() => _fromAccountId = value),
            ),
            const SizedBox(height: AppSizes.pMedium),

            Center(
              child: Icon(Icons.arrow_downward, color: AppColors.primary),
            ),
            const SizedBox(height: AppSizes.pMedium),

            Text('Vers', style: AppStyles.body.copyWith(color: AppColors.textDark)),
            const SizedBox(height: 6),
            _buildAccountDropdown(
              value: _toAccountId,
              onChanged: (value) => setState(() => _toAccountId = value),
            ),
            const SizedBox(height: AppSizes.pMedium),

            CustomInput(
              label: 'Montant (FCFA)',
              hint: 'ex : 20000',
              prefixIcon: Icons.swap_horiz,
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
              text: 'Transférer',
              isLoading: _isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDropdown({
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      hint: const Text('Sélectionne un compte'),
      items: widget.accounts.map((acc) {
        return DropdownMenuItem(
          value: acc.id,
          child: Text('${acc.name} (${acc.balance.toStringAsFixed(0)} FCFA)'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
