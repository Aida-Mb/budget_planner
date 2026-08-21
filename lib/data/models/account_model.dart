/// Représente un compte financier de l'utilisateur
class AccountModel {
  final String id;
  final String name; // ex: "Cash", "Carte BNP"
  final String type; // Cash / Carte bancaire / Épargne
  final double balance;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  /// Construit un AccountModel à partir d'un document Firestore.
  factory AccountModel.fromMap(String id, Map<String, dynamic> map) {
    return AccountModel(
      id: id,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'Cash',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convertit l'objet en Map pour l'écrire dans Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
    };
  }

  /// Crée une copie modifiée de l'objet.
  AccountModel copyWith({String? name, String? type, double? balance}) {
    return AccountModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
    );
  }
}
