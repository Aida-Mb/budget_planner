/// Représente une catégorie ajoutée par l'utilisateur, en plus des
/// catégories prédéfinies dans AppCategories (core/constants).
class CategoryModel {
  final String id;
  final String name;
  final String type; // 'expense' ou 'income'

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'expense',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'type': type};
  }
}
