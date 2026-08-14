import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/calculator_dialog.dart';
import '../../../data/models/category_model.dart';

/// Écran d'ajout OU de modification de transaction. Si [existingTransaction]
/// est fourni, le formulaire est pré-rempli et la sauvegarde met à jour
/// la transaction existante au lieu d'en créer une nouvelle.
class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  bool get _isEditing => widget.existingTransaction != null;

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategory;
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    if (existing != null) {
      _amountController.text = existing.amount.toStringAsFixed(0);
      _noteController.text = existing.note ?? '';
      _selectedType = existing.type;
      _selectedCategory = existing.category;
      _selectedAccountId = existing.accountId;
      _selectedDate = existing.date;
    }
  }

  List<String> get _staticCategories => _selectedType == TransactionType.expense
      ? AppCategories.expenseCategories
      : AppCategories.incomeCategories;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _selectedType = type;
      // On réinitialise la catégorie car la liste change selon le type
      _selectedCategory = null;
    });
  }

  Future<void> _openCalculator() async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => const CalculatorDialog(),
    );
    if (result != null) {
      setState(() {
        _amountController.text = result.toStringAsFixed(0);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis une catégorie.')),
      );
      return;
    }
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis un compte.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final transaction = TransactionModel(
        id: widget.existingTransaction?.id ?? '',
        amount: double.parse(_amountController.text.trim()),
        type: _selectedType,
        category: _selectedCategory!,
        accountId: _selectedAccountId!,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (_isEditing) {
        await _firestoreService.updateTransaction(
            widget.existingTransaction!, transaction);
      } else {
        await _firestoreService.addTransaction(transaction);
      }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la transaction' : 'Nouvelle transaction'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeToggle(),
              const SizedBox(height: AppSizes.pMedium),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomInput(
                      label: 'Montant (FCFA)',
                      hint: 'ex : 15000',
                      prefixIcon: Icons.attach_money,
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
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 56,
                    width: 56,
                    margin: const EdgeInsets.only(top: 0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.calculate_outlined,
                          color: AppColors.primary),
                      onPressed: _openCalculator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.pMedium),

              Text('Catégorie',
                  style: AppStyles.body.copyWith(color: AppColors.textDark)),
              const SizedBox(height: AppSizes.pSmall),
              _buildCategorySelector(),
              const SizedBox(height: AppSizes.pMedium),

              Text('Compte',
                  style: AppStyles.body.copyWith(color: AppColors.textDark)),
              const SizedBox(height: AppSizes.pSmall),
              _buildAccountDropdown(),
              const SizedBox(height: AppSizes.pMedium),

              Text('Date',
                  style: AppStyles.body.copyWith(color: AppColors.textDark)),
              const SizedBox(height: AppSizes.pSmall),
              _buildDatePicker(),
              const SizedBox(height: AppSizes.pMedium),

              CustomInput(
                label: 'Note (optionnel)',
                hint: 'ex : Courses de la semaine',
                prefixIcon: Icons.notes_outlined,
                controller: _noteController,
              ),
              const SizedBox(height: AppSizes.pLarge),

              CustomButton(
                text: _isEditing ? 'Modifier' : 'Enregistrer',
                isLoading: _isSaving,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSizes.pMedium),
            ],
          ),
        ),
      ),
    );
  }

  /// Sélecteur segmenté Dépense / Revenu.
  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTypeOption('Dépense', TransactionType.expense, AppColors.expense),
          _buildTypeOption('Revenu', TransactionType.income, AppColors.income),
        ],
      ),
    );
  }

  Widget _buildTypeOption(String label, TransactionType type, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? color : AppColors.textLight,
            ),
          ),
        ),
      ),
    );
  }

  /// Chips de sélection de catégorie : combine les catégories prédéfinies
  /// (AppCategories) et celles ajoutées par l'utilisateur, filtrées selon
  /// le type sélectionné (dépense/revenu). Un chip "+ Ajouter" permet
  /// d'en créer une nouvelle à la volée.
  Widget _buildCategorySelector() {
    return StreamBuilder<List<CategoryModel>>(
      stream: _firestoreService.watchCustomCategories(),
      builder: (context, snapshot) {
        final typeKey =
        _selectedType == TransactionType.expense ? 'expense' : 'income';
        final customCategories = (snapshot.data ?? [])
            .where((c) => c.type == typeKey)
            .map((c) => c.name)
            .toList();
        final allCategories = [..._staticCategories, ...customCategories];

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...allCategories.map((category) {
              final isSelected = _selectedCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) =>
                    setState(() => _selectedCategory = category),
                selectedColor: AppColors.primary.withOpacity(0.15),
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16, color: AppColors.primary),
              label: const Text('Ajouter'),
              backgroundColor: AppColors.primary.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              onPressed: () => _openAddCategoryDialog(typeKey),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAddCategoryDialog(String typeKey) async {
    final controller = TextEditingController();
    final newCategory = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'ex : Abonnements'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (newCategory != null && newCategory.isNotEmpty) {
      await _firestoreService.addCategory(newCategory, typeKey);
      setState(() => _selectedCategory = newCategory);
    }
  }

  /// Liste déroulante des comptes existants, alimentée en temps réel.
  Widget _buildAccountDropdown() {
    return StreamBuilder<List<AccountModel>>(
      stream: _firestoreService.watchAccounts(),
      builder: (context, snapshot) {
        final accounts = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        if (accounts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSizes.pMedium),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Aucun compte disponible. Crée d\'abord un compte '
                  'depuis la page "Comptes".',
              style: AppStyles.body,
            ),
          );
        }

        // Si le compte sélectionné a été supprimé entre-temps, on réinitialise.
        if (_selectedAccountId != null &&
            !accounts.any((a) => a.id == _selectedAccountId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _selectedAccountId = null);
          });
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedAccountId,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 12),
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
          items: accounts.map((acc) {
            return DropdownMenuItem(
              value: acc.id,
              child: Text('${acc.name} (${acc.balance.toStringAsFixed(0)} FCFA)'),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedAccountId = value),
        );
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.textLight, size: 18),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd/MM/yyyy').format(_selectedDate),
              style: AppStyles.body.copyWith(color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}
