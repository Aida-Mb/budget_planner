/// Type de transaction possible.
enum TransactionType { income, expense }

/// Représente une transaction (revenu ou dépense) liée à un compte.
class TransactionModel {
  final String id;
  final double amount;
  final TransactionType type;
  final String category;
  final String accountId;
  final DateTime date;
  final String? note;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.accountId,
    required this.date,
    this.note,
  });

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: (map['type'] as String? ?? 'expense') == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      category: map['category'] as String? ?? 'Autres',
      accountId: map['accountId'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category': category,
      'accountId': accountId,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  /// Montant signé : positif pour un revenu, négatif pour une dépense.
  double get signedAmount =>
      type == TransactionType.income ? amount : -amount;
}
