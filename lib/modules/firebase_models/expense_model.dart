import 'package:cloud_firestore/cloud_firestore.dart';

// New V2 Model for the updated Firestore structure
class ExpenseModel {
  final String modelName;
  final List<String> paymentModes;
  final List<String> categories;
  final Map<String, ExpenseTransactionV2> transactions;

  ExpenseModel({
    required this.modelName,
    required this.paymentModes,
    required this.categories,
    required this.transactions,
  });

  // Empty model for initial creation
  factory ExpenseModel.empty() {
    return ExpenseModel(
      modelName: 'Test',
      paymentModes: [],
      categories: [],
      transactions: {},
    );
  }

  // From Map
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    final transactionsMap = <String, ExpenseTransactionV2>{};
    final transactionsData = map['transactions'] as Map<String, dynamic>? ?? {};
    
    transactionsData.forEach((key, value) {
      transactionsMap[key] = ExpenseTransactionV2.fromMap(value as Map<String, dynamic>);
    });

    return ExpenseModel(
      modelName: map['modelName'] ?? 'Test',
      paymentModes: List<String>.from(map['paymentModes'] ?? []),
      categories: List<String>.from(map['categories'] ?? []),
      transactions: transactionsMap,
    );
  }

  // To Map
  Map<String, dynamic> toMap() {
    final transactionsMap = <String, dynamic>{};
    transactions.forEach((key, transaction) {
      transactionsMap[key] = transaction.toMap();
    });

    return {
      'modelName': modelName,
      'paymentModes': paymentModes,
      'categories': categories,
      'transactions': transactionsMap,
    };
  }

  // From Firestore DocumentSnapshot
  factory ExpenseModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    return ExpenseModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Update from Firestore DocumentSnapshot
  ExpenseModel updateFromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel.fromMap(data);
  }
}

class ExpenseTransaction {
  final String id;
  final String date;
  final String mode;
  final String category;
  final String description;
  final double amount;

  ExpenseTransaction({
    required this.id,
    required this.date,
    required this.mode,
    required this.category,
    required this.description,
    required this.amount,
  });

  // From Map
  factory ExpenseTransaction.fromMap(Map<String, dynamic> map) {
    return ExpenseTransaction(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      mode: map['mode'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }

  // To Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'mode': mode,
      'category': category,
      'description': description,
      'amount': amount,
    };
  }
}

// New V2 Transaction model for the updated structure
class ExpenseTransactionV2 {
  final String id;
  final String date;
  final String mode;
  final String category;
  final String description;
  final double amount;
  final bool isSynced;

  ExpenseTransactionV2({
    required this.id,
    required this.date,
    required this.mode,
    required this.category,
    required this.description,
    required this.amount,
    this.isSynced = false,
  });

  // From Map
  factory ExpenseTransactionV2.fromMap(Map<String, dynamic> map) {
    return ExpenseTransactionV2(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      mode: map['mode'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      isSynced: map['isSynced'] ?? false,
    );
  }

  // To Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'mode': mode,
      'category': category,
      'description': description,
      'amount': amount,
      'isSynced': isSynced,
    };
  }
}

class TransactionUser {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String createdAt;
  final bool isActive;

  TransactionUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.createdAt,
    required this.isActive,
  });

  // From Map
  factory TransactionUser.fromMap(Map<String, dynamic> map) {
    return TransactionUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      createdAt: map['createdAt'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  // To Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}
