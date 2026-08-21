import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';

/// Centralise TOUS les accès à Firestore.
/// Aucun écran n'importer `cloud_firestore` directement : il passe toujours par ce service.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _accountsRef => _db.collection('accounts');
  CollectionReference get _transactionsRef => _db.collection('transactions');
  CollectionReference get _goalsRef => _db.collection('goals');
  CollectionReference get _budgetsRef => _db.collection('budgets');
  CollectionReference get _categoriesRef => _db.collection('categories');

  // ---------------------------------------------------------------------
  // COMPTES (Accounts)
  // ---------------------------------------------------------------------

  /// Flux temps réel de la liste des comptes.
  /// Utilisé avec StreamBuilder dans les écrans.
  Stream<List<AccountModel>> watchAccounts() {
    return _accountsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AccountModel.fromMap(
          doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> addAccount(AccountModel account) async {
    try {
      await _accountsRef.add(account.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la création du compte : $e');
    }
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    try {
      await _accountsRef.doc(accountId).update({'balance': newBalance});
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du solde : $e');
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      await _accountsRef.doc(accountId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du compte : $e');
    }
  }

  // ---------------------------------------------------------------------
  // TRANSACTIONS
  // ---------------------------------------------------------------------

  /// Flux temps réel de toutes les transactions, triées par date décroissante.
  Stream<List<TransactionModel>> watchTransactions() {
    return _transactionsRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(
          doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Ajoute une transaction ET met à jour le solde du compte associé
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _db.runTransaction((firestoreTx) async {
        final accountDoc =
        await firestoreTx.get(_accountsRef.doc(transaction.accountId));

        if (!accountDoc.exists) {
          throw Exception('Compte introuvable.');
        }

        final currentBalance =
        (accountDoc.data() as Map<String, dynamic>)['balance'] as num;
        final newBalance = currentBalance + transaction.signedAmount;

        // 1. Écrire la nouvelle transaction
        firestoreTx.set(_transactionsRef.doc(), transaction.toMap());

        // 2. Mettre à jour le solde du compte
        firestoreTx.update(
          _accountsRef.doc(transaction.accountId),
          {'balance': newBalance},
        );
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la transaction : $e');
    }
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    try {
      await _db.runTransaction((firestoreTx) async {
        final accountDoc =
        await firestoreTx.get(_accountsRef.doc(transaction.accountId));

        if (accountDoc.exists) {
          final currentBalance =
          (accountDoc.data() as Map<String, dynamic>)['balance'] as num;
          final restoredBalance = currentBalance - transaction.signedAmount;
          firestoreTx.update(
            _accountsRef.doc(transaction.accountId),
            {'balance': restoredBalance},
          );
        }

        firestoreTx.delete(_transactionsRef.doc(transaction.id));
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression : $e');
    }
  }

  /// Modifie une transaction existante.
  Future<void> updateTransaction(
      TransactionModel oldTransaction, TransactionModel newTransaction) async {
    try {
      await _db.runTransaction((firestoreTx) async {
        // --- 1. Lectures (toutes AVANT les écritures, règle Firestore) ---
        final oldAccountDoc =
        await firestoreTx.get(_accountsRef.doc(oldTransaction.accountId));

        final sameAccount =
            oldTransaction.accountId == newTransaction.accountId;

        final newAccountDoc = sameAccount
            ? oldAccountDoc
            : await firestoreTx.get(_accountsRef.doc(newTransaction.accountId));

        if (!oldAccountDoc.exists || !newAccountDoc.exists) {
          throw Exception('Compte introuvable.');
        }

        // --- 2. Calculs ---
        final oldAccountBalance =
        (oldAccountDoc.data() as Map<String, dynamic>)['balance'] as num;

        if (sameAccount) {
          // Un seul compte concerné : on retire l'ancien effet et on
          // applique le nouveau en une seule mise à jour.
          final newBalance = oldAccountBalance -
              oldTransaction.signedAmount +
              newTransaction.signedAmount;
          firestoreTx.update(
            _accountsRef.doc(oldTransaction.accountId),
            {'balance': newBalance},
          );
        } else {
          // Deux comptes différents : on annule sur l'ancien, on applique sur le nouveau.
          final newAccountBalance =
          (newAccountDoc.data() as Map<String, dynamic>)['balance'] as num;

          firestoreTx.update(
            _accountsRef.doc(oldTransaction.accountId),
            {'balance': oldAccountBalance - oldTransaction.signedAmount},
          );
          firestoreTx.update(
            _accountsRef.doc(newTransaction.accountId),
            {'balance': newAccountBalance + newTransaction.signedAmount},
          );
        }

        // --- 3. Mise à jour du document transaction lui-même ---
        firestoreTx.update(
          _transactionsRef.doc(oldTransaction.id),
          newTransaction.toMap(),
        );
      });
    } catch (e) {
      throw Exception('Erreur lors de la modification : $e');
    }
  }

  // ---------------------------------------------------------------------
  // OBJECTIFS D'ÉPARGNE (Goals)
  // ---------------------------------------------------------------------

  /// Flux temps réel de la liste des objectifs.
  Stream<List<GoalModel>> watchGoals() {
    return _goalsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
          GoalModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> addGoal(GoalModel goal) async {
    try {
      await _goalsRef.add(goal.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'objectif : $e');
    }
  }

  /// Ajoute une contribution à un objectif existant
  Future<void> contributeToGoal(String goalId, double amount) async {
    try {
      await _db.runTransaction((firestoreTx) async {
        final goalDoc = await firestoreTx.get(_goalsRef.doc(goalId));
        if (!goalDoc.exists) {
          throw Exception('Objectif introuvable.');
        }
        final currentAmount =
        (goalDoc.data() as Map<String, dynamic>)['currentAmount'] as num;
        firestoreTx.update(
          _goalsRef.doc(goalId),
          {'currentAmount': currentAmount + amount},
        );
      });
    } catch (e) {
      throw Exception('Erreur lors de la contribution : $e');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _goalsRef.doc(goalId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'objectif : $e');
    }
  }

  // ---------------------------------------------------------------------
  // BUDGETS PAR CATÉGORIE
  // ---------------------------------------------------------------------

  /// Flux temps réel des limites budgétaires définies.
  Stream<List<BudgetModel>> watchBudgets() {
    return _budgetsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BudgetModel.fromMap(
          doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Crée ou met à jour la limite d'une catégorie.
  /// Utilise le nom de la catégorie comme ID de document : un seul
  /// document par catégorie, pas de doublons possibles.
  Future<void> setBudgetLimit(String category, double limitAmount) async {
    try {
      await _budgetsRef.doc(category).set(
        BudgetModel(category: category, limitAmount: limitAmount).toMap(),
      );
    } catch (e) {
      throw Exception('Erreur lors de la définition du budget : $e');
    }
  }

  Future<void> deleteBudget(String category) async {
    try {
      await _budgetsRef.doc(category).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du budget : $e');
    }
  }

  // ---------------------------------------------------------------------
  // TRANSFERT ENTRE COMPTES
  // ---------------------------------------------------------------------

  /// Transfère un montant d'un compte vers un autre.
  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
  }) async {
    if (fromAccountId == toAccountId) {
      throw Exception('Choisis deux comptes différents.');
    }
    try {
      await _db.runTransaction((firestoreTx) async {
        final fromDoc = await firestoreTx.get(_accountsRef.doc(fromAccountId));
        final toDoc = await firestoreTx.get(_accountsRef.doc(toAccountId));

        if (!fromDoc.exists || !toDoc.exists) {
          throw Exception('Compte introuvable.');
        }

        final fromBalance =
        (fromDoc.data() as Map<String, dynamic>)['balance'] as num;
        final toBalance =
        (toDoc.data() as Map<String, dynamic>)['balance'] as num;

        if (fromBalance < amount) {
          throw Exception('Solde insuffisant sur le compte source.');
        }

        firestoreTx.update(
          _accountsRef.doc(fromAccountId),
          {'balance': fromBalance - amount},
        );
        firestoreTx.update(
          _accountsRef.doc(toAccountId),
          {'balance': toBalance + amount},
        );
      });
    } catch (e) {
      throw Exception('Erreur lors du transfert : $e');
    }
  }

  // ---------------------------------------------------------------------
  // CATÉGORIES PERSONNALISÉES
  // ---------------------------------------------------------------------

  /// Flux temps réel des catégories ajoutées par l'utilisateur, en plus des catégories prédéfinies dans AppCategories.
  Stream<List<CategoryModel>> watchCustomCategories() {
    return _categoriesRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(
          doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> addCategory(String name, String type) async {
    try {
      await _categoriesRef.add({'name': name, 'type': type});
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la catégorie : $e');
    }
  }
}

