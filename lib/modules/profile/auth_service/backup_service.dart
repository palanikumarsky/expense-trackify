import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:expensetrackify/modules/dao/expense_account_dao.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/modules/dao/category_dao.dart';
import 'package:expensetrackify/modules/dao/mode_dao.dart';
import 'package:drift/drift.dart';
import 'package:expensetrackify/modules/firebase_models/expense_model.dart';


class SyncService {
  static final SyncService _instance = SyncService._internal();
  SyncService._internal();
  factory SyncService() => _instance;

  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;



  /// Sync all local data to Firebase Firestore using ExpenseModelV2
  Future<SyncResult> syncToFirebaseV2() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return SyncResult(
          success: false,
          message: 'User not authenticated',
          syncedCount: 0,
        );
      }
      
      final userId = currentUser.uid;
      final transactionDao = TransactionDao(appDatabase);
      final categoryDao = CategoryDao(appDatabase);
      final modeDao = ModeDao(appDatabase);
      
      // Get all local data
      final localTransactions = await transactionDao.getTransactions();
      final categories = await categoryDao.getCategories();
      final modes = await modeDao.getModes();
      
      // First, download existing data from Firebase
      final cloudTransactions = await _downloadTransactionsFromFirebase(userId);
      
      // Compare local and cloud transactions to find new ones
      final newTransactions = _findNewTransactions(localTransactions, cloudTransactions);
      
      if (newTransactions.isEmpty) {
        return SyncResult(
          success: true,
          message: 'No new transactions to sync. All data is up to date.',
          syncedCount: 0,
        );
      }
      
      // Map to ExpenseModelV2
      final paymentModes = modes.map((m) => m.name).toList();
      final categoriesList = categories.map((c) => c.name).toList();
      
      // Map only new transactions to ExpenseTransactionV2 objects
      final transactionsMap = <String, ExpenseTransactionV2>{};
      for (final transactionWithDetails in newTransactions) {
        final transaction = transactionWithDetails.transaction;
        final category = transactionWithDetails.category;
        final mode = transactionWithDetails.mode;
        transactionsMap[transaction.id] = ExpenseTransactionV2(
          id: transaction.id,
          date: transaction.date,
          mode: mode?.name ?? 'Unknown Mode',
          category: category?.name ?? 'Unknown Category',
          description: transaction.description,
          amount: transaction.amount,
          isSynced: true,
        );
      }
      
      final expenseModelV2 = ExpenseModel(
        modelName: 'Test',
        paymentModes: paymentModes,
        categories: categoriesList,
        transactions: transactionsMap,
      );
      
      // Upload to the new structure: users/userId/expenseModels/modelId/
      final modelId = expenseModelV2.modelName;
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('expenseModels')
          .doc(modelId);
      
      await docRef.set({
        'modelName': expenseModelV2.modelName,
        'paymentModes': expenseModelV2.paymentModes,
        'categories': expenseModelV2.categories,
      });
      
      // Add each new transaction as a separate document
      final transactionsCollection = docRef.collection('transactions');
      for (final entry in transactionsMap.entries) {
        await transactionsCollection.doc(entry.key).set(entry.value.toMap());
      }
      
      return SyncResult(
        success: true,
        message: 'Successfully synced ${transactionsMap.length} new transactions to cloud (Model: $modelId)',
        syncedCount: transactionsMap.length,
      );
    } catch (error) {
      return SyncResult(
        success: false,
        message: 'Failed to sync to ExpenseModelV2: $error',
        syncedCount: 0,
      );
    }
  }

  /// Download transactions from Firebase
  Future<Map<String, ExpenseTransactionV2>> _downloadTransactionsFromFirebase(String userId) async {
    try {
      final modelsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('expenseModels');
      
      final modelsSnapshot = await modelsRef.get();
      if (modelsSnapshot.docs.isEmpty) {
        return {};
      }
      
      // Find the latest model
      firestore.DocumentSnapshot? latestModelDoc;
      for (final doc in modelsSnapshot.docs) {
        if (latestModelDoc == null || doc.id.compareTo(latestModelDoc.id) > 0) {
          latestModelDoc = doc;
        }
      }
      
      if (latestModelDoc == null) {
        return {};
      }
      
      // Get transactions from the latest model
      final transactionsCollection = latestModelDoc.reference.collection('transactions');
      final transactionsSnapshot = await transactionsCollection.get();
      
      final transactionsMap = <String, ExpenseTransactionV2>{};
      for (final doc in transactionsSnapshot.docs) {
        final data = doc.data();
        transactionsMap[doc.id] = ExpenseTransactionV2.fromMap(data);
      }
      
      return transactionsMap;
    } catch (error) {
      return {};
    }
  }

  /// Find transactions that exist locally but not in cloud
  List<dynamic> _findNewTransactions(List<dynamic> localTransactions, Map<String, ExpenseTransactionV2> cloudTransactions) {
    final newTransactions = <dynamic>[];
    
          for (final transactionWithDetails in localTransactions) {
        final transaction = transactionWithDetails.transaction;
        
        // Create a unique key for comparison
        final transactionKey = '${transaction.description}_${transaction.amount}_${transaction.date}';
      
      // Check if this transaction exists in cloud
      bool existsInCloud = false;
      for (final cloudTransaction in cloudTransactions.values) {
        final cloudKey = '${cloudTransaction.description}_${cloudTransaction.amount}_${cloudTransaction.date}';
        if (transactionKey == cloudKey) {
          existsInCloud = true;
          break;
        }
      }
      
      // If not found in cloud, it's a new transaction
      if (!existsInCloud) {
        newTransactions.add(transactionWithDetails);
      }
    }
    
    return newTransactions;
  }

  /// Get sync information - returns details about new transactions that need to be uploaded
  Future<SyncInfo> getSyncInfo() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return SyncInfo(
          success: false,
          message: 'User not authenticated',
          newTransactionsCount: 0,
          newTransactions: [],
        );
      }
      
      final userId = currentUser.uid;
      final transactionDao = TransactionDao(appDatabase);
      
      // Get all local data
      final localTransactions = await transactionDao.getTransactions();
      
      // First, download existing data from Firebase
      final cloudTransactions = await _downloadTransactionsFromFirebase(userId);
      
      // Compare local and cloud transactions to find new ones
      final newTransactions = _findNewTransactions(localTransactions, cloudTransactions);
      
      return SyncInfo(
        success: true,
        message: 'Found ${newTransactions.length} new transactions to sync',
        newTransactionsCount: newTransactions.length,
        newTransactions: newTransactions,
      );
    } catch (error) {
      return SyncInfo(
        success: false,
        message: 'Failed to get sync info: $error',
        newTransactionsCount: 0,
        newTransactions: [],
      );
    }
  }

  /// Sync all data from Firebase ExpenseModelV2 to local database
  Future<SyncResult> syncFromFirebase() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return SyncResult(
          success: false,
          message: 'User not authenticated',
          syncedCount: 0,
        );
      }
      final userId = currentUser.uid;
      final transactionDao = TransactionDao(appDatabase);
      final categoryDao = CategoryDao(appDatabase);
      final modeDao = ModeDao(appDatabase);
      // Download ExpenseModelV2 from the latest model
      final modelsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('expenseModels');
      final modelsSnapshot = await modelsRef.get();
      if (modelsSnapshot.docs.isEmpty) {
        return SyncResult(
          success: false,
          message: 'No cloud backup found for this user',
          syncedCount: 0,
        );
      }
      // Find the latest model by comparing document IDs (they are timestamps)
      firestore.DocumentSnapshot? latestModelDoc;
      String? latestModelId;
      for (final doc in modelsSnapshot.docs) {
        if (latestModelDoc == null || doc.id.compareTo(latestModelDoc.id) > 0) {
          latestModelDoc = doc;
          latestModelId = doc.id;
        }
      }
      if (latestModelDoc == null) {
        return SyncResult(
          success: false,
          message: 'No valid cloud backup found for this user',
          syncedCount: 0,
        );
      }
      final expenseModelV2 = ExpenseModel.fromDocumentSnapshot(latestModelDoc);
      // Store the latest model name in local db
      final expenseAccountDao = ExpenseAccountDao(appDatabase);
      await expenseAccountDao.addExpenseAccount(ExpensesAccountsCompanion.insert(name: expenseModelV2.modelName));
      int totalSynced = 0;
      // Sync payment modes
      final localModes = await modeDao.getModes();
      final localModeNames = localModes.map((m) => m.name).toSet();
      for (final modeName in expenseModelV2.paymentModes) {
        if (!localModeNames.contains(modeName)) {
          await modeDao.createMode(ModesCompanion.insert(name: modeName));
          totalSynced++;
        }
      }
      // Sync categories
      final localCategories = await categoryDao.getCategories();
      final localCategoryNames = localCategories.map((c) => c.name).toSet();
      for (final categoryName in expenseModelV2.categories) {
        if (!localCategoryNames.contains(categoryName)) {
          await categoryDao.createCategory(CategoriesCompanion.insert(name: categoryName));
          totalSynced++;
        }
      }
      // Sync transactions
      final localTransactions = await transactionDao.getTransactions();
      final localTransactionDescriptions = localTransactions.map((t) => '${t.transaction.description}_${t.transaction.amount}_${t.transaction.date}').toSet();
      for (final entry in expenseModelV2.transactions.entries) {
        final expenseTransaction = entry.value;
        final transactionKey = '${expenseTransaction.description}_${expenseTransaction.amount}_${expenseTransaction.date}';
        if (!localTransactionDescriptions.contains(transactionKey)) {
          // Find mode and category IDs by name
          final modeId = await _getModeIdByName(expenseTransaction.mode);
          final categoryId = await _getCategoryIdByName(expenseTransaction.category);
          if (modeId != null && categoryId != null) {
            final transactionCompanion = TransactionsCompanion(
              description: Value(expenseTransaction.description),
              amount: Value(expenseTransaction.amount),
              date: Value(expenseTransaction.date),
              modeId: Value(modeId),
              categoryId: Value(categoryId),
              isSynced: Value(true),
            );
            await transactionDao.createTransaction(transactionCompanion);
            totalSynced++;
          }
        }
      }
      return SyncResult(
        success: true,
        message: 'Successfully synced $totalSynced items from cloud (Model: $latestModelId)',
        syncedCount: totalSynced,
      );
    } catch (error) {
      return SyncResult(
        success: false,
        message: 'Failed to sync from ExpenseModelV2: $error',
        syncedCount: 0,
      );
    }
  }

  /// Sync all local data to Firebase Firestore using ExpenseModelV2
  Future<SyncResult> syncTransactionsToFirebase() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return SyncResult(
          success: false,
          message: 'User not authenticated',
          syncedCount: 0,
        );
      }
      final userId = currentUser.uid;
      final transactionDao = TransactionDao(appDatabase);
      final categoryDao = CategoryDao(appDatabase);
      final modeDao = ModeDao(appDatabase);
      // Get all local data
      final transactions = await transactionDao.getTransactions();
      final categories = await categoryDao.getCategories();
      final modes = await modeDao.getModes();
      // Map to ExpenseModelV2
      final paymentModes = modes.map((m) => m.name).toList();
      final categoriesList = categories.map((c) => c.name).toList();
      // Map transactions to ExpenseTransactionV2 objects with auto-generated IDs
      final transactionsMap = <String, ExpenseTransactionV2>{};
      for (final transactionWithDetails in transactions) {
        final transaction = transactionWithDetails.transaction;
        final category = transactionWithDetails.category;
        final mode = transactionWithDetails.mode;
        transactionsMap[transaction.id] = ExpenseTransactionV2(
          id: transaction.id,
          date: transaction.date,
          mode: mode?.name ?? 'Unknown Mode',
          category: category?.name ?? 'Unknown Category',
          description: transaction.description,
          amount: transaction.amount,
          isSynced: true,
        );
      }
      final expenseModelV2 = ExpenseModel(
        modelName: 'Test',
        paymentModes: paymentModes,
        categories: categoriesList,
        transactions: transactionsMap,
      );
      // Upload to the new structure: users/userId/expenseModels/modelId/
      final modelId = expenseModelV2.modelName;
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('expenseModels')
          .doc(modelId);
      await docRef.set(expenseModelV2.toMap());
      return SyncResult(
        success: true,
        message: 'Successfully synced ${transactionsMap.length} transactions to cloud (Model: $modelId)',
        syncedCount: transactionsMap.length,
      );
    } catch (error) {
      return SyncResult(
        success: false,
        message: 'Failed to sync to ExpenseModelV2: $error',
        syncedCount: 0,
      );
    }
  }

  /// Create a new transaction collection for family sharing
  Future<SyncResult> createTransactionCollection(String collectionName, List<String> memberEmails) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return SyncResult(
          success: false,
          message: 'User not authenticated',
          syncedCount: 0,
        );
      }

      final userId = currentUser.uid;
      
      // Create collection document
      final collectionData = {
        'name': collectionName,
        'createdBy': userId,
        'createdAt': DateTime.now().toIso8601String(),
        'members': [userId, ...memberEmails], // Add creator and members
        'isActive': true,
      };

      final collectionRef = _firestore.collection('transactionCollections').doc();
      await collectionRef.set(collectionData);

      return SyncResult(
        success: true,
        message: 'Successfully created collection: $collectionName',
        syncedCount: 1,
      );

    } catch (error) {
      return SyncResult(
        success: false,
        message: 'Failed to create collection: $error',
        syncedCount: 0,
      );
    }
  }

  /// Get all transaction collections for the current user
  Future<List<TransactionCollection>> getUserCollections() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final userId = currentUser.uid;
      
      // Get collections where user is a member
      final collectionsSnapshot = await _firestore
          .collection('transactionCollections')
          .where('members', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return collectionsSnapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionCollection(
          id: doc.id,
          name: data['name'],
          createdBy: data['createdBy'],
          members: List<String>.from(data['members']),
          createdAt: data['createdAt'],
        );
      }).toList();

    } catch (error) {
      return [];
    }
  }

  /// Helper method to get mode ID by name
  Future<int?> _getModeIdByName(String modeName) async {
    final modeDao = ModeDao(appDatabase);
    final modes = await modeDao.getModes();
    final mode = modes.firstWhere(
      (m) => m.name == modeName,
      orElse: () => throw Exception('Mode not found: $modeName'),
    );
    return mode.id;
  }

  /// Helper method to get category ID by name
  Future<int?> _getCategoryIdByName(String categoryName) async {
    final categoryDao = CategoryDao(appDatabase);
    final categories = await categoryDao.getCategories();
    final category = categories.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => throw Exception('Category not found: $categoryName'),
    );
    return category.id;
  }

  /// If local DB is empty and cloud has transactions, fetch from cloud and store in local
  Future<SyncResult> syncIfLocalEmptyAndCloudHasData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return SyncResult(
          success: false,
          message: 'User not authenticated',
          syncedCount: 0,
        );
      }
      final userId = currentUser.uid;
      final transactionDao = TransactionDao(appDatabase);
      // Check local transactions
      final localTransactions = await transactionDao.getTransactions();
      if (localTransactions.isNotEmpty) {
        return SyncResult(
          success: true,
          message: 'Local database already has transactions.',
          syncedCount: 0,
        );
      }
      // Download from cloud
      final cloudTransactions = await _downloadTransactionsFromFirebase(userId);
      if (cloudTransactions.isEmpty) {
        return SyncResult(
          success: true,
          message: 'No transactions found in cloud.',
          syncedCount: 0,
        );
      }
      // Insert all cloud transactions into local DB
      int inserted = 0;
      for (final entry in cloudTransactions.entries) {
        final expenseTransaction = entry.value;
        // Find mode and category IDs by name
        final modeId = await _getModeIdByName(expenseTransaction.mode);
        final categoryId = await _getCategoryIdByName(expenseTransaction.category);
        if (modeId != null && categoryId != null) {
          final transactionCompanion = TransactionsCompanion(
            id: Value(expenseTransaction.id),
            description: Value(expenseTransaction.description),
            amount: Value(expenseTransaction.amount),
            date: Value(expenseTransaction.date),
            modeId: Value(modeId),
            categoryId: Value(categoryId),
            isSynced: Value(true),
          );
          await transactionDao.createTransaction(transactionCompanion);
          inserted++;
        }
      }
      return SyncResult(
        success: true,
        message: 'Fetched $inserted transactions from cloud to local DB.',
        syncedCount: inserted,
      );
    } catch (error) {
      return SyncResult(
        success: false,
        message: 'Failed to sync from cloud: $error',
        syncedCount: 0,
      );
    }
  }

  /// Update a single transaction in Firebase when it's edited locally
  Future<SyncResult> updateTransactionInFirebase(Transaction transaction, String modeName, String categoryName) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return SyncResult(
          success: false,
          message: 'User not authenticated',
          syncedCount: 0,
        );
      }
      
      final userId = currentUser.uid;
      
      // Find the latest model
      final modelsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('expenseModels');
      
      final modelsSnapshot = await modelsRef.get();
      if (modelsSnapshot.docs.isEmpty) {
        return SyncResult(
          success: false,
          message: 'No cloud backup found for this user',
          syncedCount: 0,
        );
      }
      
      // Find the latest model
      firestore.DocumentSnapshot? latestModelDoc;
      for (final doc in modelsSnapshot.docs) {
        if (latestModelDoc == null || doc.id.compareTo(latestModelDoc.id) > 0) {
          latestModelDoc = doc;
        }
      }
      
      if (latestModelDoc == null) {
        return SyncResult(
          success: false,
          message: 'No valid cloud backup found for this user',
          syncedCount: 0,
        );
      }
      
      // Update the transaction in Firebase
      final transactionsCollection = latestModelDoc.reference.collection('transactions');
      final transactionDoc = transactionsCollection.doc(transaction.id);
      
      // Check if the transaction exists in Firebase
      final transactionSnapshot = await transactionDoc.get();
      if (!transactionSnapshot.exists) {
        return SyncResult(
          success: false,
          message: 'Transaction not found in cloud',
          syncedCount: 0,
        );
      }
      
      // Create updated ExpenseTransactionV2
      final updatedTransaction = ExpenseTransactionV2(
        id: transaction.id,
        date: transaction.date,
        mode: modeName,
        category: categoryName,
        description: transaction.description,
        amount: transaction.amount,
        isSynced: true,
      );
      
      // Update the transaction in Firebase
      await transactionDoc.set(updatedTransaction.toMap());
      
      return SyncResult(
        success: true,
        message: 'Successfully updated transaction in cloud',
        syncedCount: 1,
      );
    } catch (error) {
      return SyncResult(
        success: false,
        message: 'Failed to update transaction in cloud: $error',
        syncedCount: 0,
      );
    }
  }

  /// Delete a single transaction from Firebase when it's deleted locally
  Future<SyncResult> deleteTransactionInFirebase(String transactionId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return SyncResult(
          success: false,
          message: 'User not authenticated',
          syncedCount: 0,
        );
      }
      
      final userId = currentUser.uid;
      
      // Find the latest model
      final modelsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('expenseModels');
      
      final modelsSnapshot = await modelsRef.get();
      if (modelsSnapshot.docs.isEmpty) {
        return SyncResult(
          success: false,
          message: 'No cloud backup found for this user',
          syncedCount: 0,
        );
      }
      
      // Find the latest model
      firestore.DocumentSnapshot? latestModelDoc;
      for (final doc in modelsSnapshot.docs) {
        if (latestModelDoc == null || doc.id.compareTo(latestModelDoc.id) > 0) {
          latestModelDoc = doc;
        }
      }
      
      if (latestModelDoc == null) {
        return SyncResult(
          success: false,
          message: 'No valid cloud backup found for this user',
          syncedCount: 0,
        );
      }
      
      // Delete the transaction from Firebase
      final transactionsCollection = latestModelDoc.reference.collection('transactions');
      final transactionDoc = transactionsCollection.doc(transactionId);
      
      // Check if the transaction exists in Firebase
      final transactionSnapshot = await transactionDoc.get();
      if (!transactionSnapshot.exists) {
        return SyncResult(
          success: false,
          message: 'Transaction not found in cloud',
          syncedCount: 0,
        );
      }
      
      // Delete the transaction from Firebase
      await transactionDoc.delete();
      
      return SyncResult(
        success: true,
        message: 'Successfully deleted transaction from cloud',
        syncedCount: 1,
      );
    } catch (error) {
      return SyncResult(
        success: false,
        message: 'Failed to delete transaction from cloud: $error',
        syncedCount: 0,
      );
    }
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
  });
}

class TransactionCollection {
  final String id;
  final String name;
  final String createdBy;
  final List<String> members;
  final String createdAt;

  TransactionCollection({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.members,
    required this.createdAt,
  });
}

class SyncInfo {
  final bool success;
  final String message;
  final int newTransactionsCount;
  final List<dynamic> newTransactions;

  SyncInfo({
    required this.success,
    required this.message,
    required this.newTransactionsCount,
    required this.newTransactions,
  });
} 