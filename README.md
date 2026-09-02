# BudgetPlanner 

Application mobile de gestion de budget personnel, développée avec **Flutter** dans le cadre du cours de **Développement Mobile**.


##  Présentation

Suivre ses dépenses, organiser ses revenus et épargner pour des projets futurs restent des défis du quotidien. Les solutions existantes sont souvent trop complexes ou nécessitent la création d'un compte en ligne, ce qui freine leur adoption.

**BudgetPlanner** est une application mobile intuitive pensée pour aider chaque utilisateur à prendre le contrôle de ses finances personnelles : suivre ses comptes, ses transactions, ses objectifs d'épargne et son budget par catégorie, le tout de façon simple et visuelle.

##  Fonctionnalités

### Navigation principale
- Onboarding de présentation au premier lancement (3 écrans)
- Navigation entre 4 pages : **Home**, **Insights**, **Comptes**, **Transactions**

###  Home
- Solde total en temps réel (agrégation de tous les comptes)
- Diagramme en barres Revenus vs Dépenses (7 derniers jours)
- Courbe de tendance du solde total (7 derniers jours)
- Historique des 5 dernières transactions

###  Insights
- Répartition des dépenses par catégorie (graphique camembert interactif)
- Budget par catégorie : définition d'une limite mensuelle et suivi de
  la progression (dépensé / restant), avec code couleur d'alerte

### Comptes
- Gestion de plusieurs comptes (Cash, Carte bancaire, Épargne)
- Transfert d'argent entre comptes
- Objectifs d'épargne personnalisés (nom, montant cible) avec barre de
  progression et système de contribution
- Suppression avec confirmation (swipe)

###  Transactions
- Historique complet et chronologique
- Ajout d'une transaction : montant, type (revenu/dépense), catégorie,
  compte associé, date, note
- **Catégories personnalisées** ajoutables directement depuis le formulaire
- Calculatrice intégrée pour calculer un montant avant de valider
- Modification et suppression (avec confirmation) d'une transaction
- Recherche par catégorie ou note
- Filtre par période (Aujourd'hui / 7 jours / Ce mois / Tout)



## Architecture

Le projet suit une architecture en couches, avec une séparation stricte
entre les données, la logique d'accès et l'interface :

```
lib/
├── core/
│   └── constants/          # Design system : couleurs, tailles, styles, catégories
├── data/
│   ├── models/             # Account, Transaction, Goal, Budget, Category
│   └── services/           # firestore_service.dart : tous les accès à la base
└── presentation/
    ├── screens/             # Un dossier par page (home, insights, accounts, transactions...)
    └── widgets/             # Composants réutilisables (boutons, cartes, graphiques...)
```

**Principe clé :** aucun écran n'accède directement à Firestore, tout passe
par `FirestoreService`, ce qui centralise la logique métier et facilite
la maintenance.

##  Technologies utilisées

| Technologie | Rôle |
|---|---|
| Flutter | SDK principal de développement mobile |
| Dart | Langage de programmation |
| Cloud Firestore | Base de données temps réel (comptes, transactions, objectifs, budgets, catégories) |
| fl_chart | Graphiques (camembert, barres, courbe) |
| shared_preferences | Mémorisation de l'onboarding déjà vu |
| intl | Formatage des montants et des dates |

##  Installation et lancement

### Prérequis
- Flutter SDK installé (`flutter doctor` sans erreur bloquante)

### Étapes

1. **Cloner le dépôt et installer les dépendances**
   ```bash
   git clone https://github.com/Aida-Mb/budget_planner.git
   cd budget_planner
   flutter pub get
   ```

2. **Lancer l'application**
   ```bash
   flutter run
   ```

La configuration Firebase (`lib/firebase_options.dart`) est déjà incluse
dans le dépôt, aucune configuration supplémentaire n'est nécessaire,
l'application se connecte directement à l'instance Firestore du projet.

Aucune donnée de test n'est pré-remplie : à la première utilisation,
créer un compte depuis la page **Comptes** avant d'ajouter des
transactions.

##  Structure des données (Firestore)

| Collection | Champs | Description |
|---|---|---|
| `accounts` | `name`, `type`, `balance` | Comptes de l'utilisateur |
| `transactions` | `amount`, `type`, `category`, `accountId`, `date`, `note` | Historique des mouvements |
| `goals` | `title`, `targetAmount`, `currentAmount`, `deadline` | Objectifs d'épargne |
| `budgets` | `category` *(= ID du document)*, `limitAmount` | Limites budgétaires par catégorie |
| `categories` | `name`, `type` | Catégories ajoutées par l'utilisateur |

## Limites et Perspectives 

- Export des données (CSV/PDF)
- Le graphique "Répartition des dépenses" se limite au mois en cours
