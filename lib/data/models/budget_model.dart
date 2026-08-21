/// Représente une limite budgétaire définie pour une catégorie de dépense
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
