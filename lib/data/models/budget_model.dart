/// Représente une limite budgétaire définie pour une catégorie de dépense
/// (ex : "Alimentation" → 100 000 FCFA / mois).
/// Un seul document par catégorie dans Firestore (l'id du document
/// est directement le nom de la catégorie, ce qui simplifie la mise à jour).
class BudgetModel {
  final String category;
  final double limitAmount;

  BudgetModel({
    required this.category,
    required this.limitAmount,
  });

  factory BudgetModel.fromMap(String category, Map<String, dynamic> map) {
    return BudgetModel(
      category: category,
      limitAmount: (map['limitAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limitAmount': limitAmount,
    };
  }
}
