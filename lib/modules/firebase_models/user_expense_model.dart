// import 'package:drift/drift.dart';
// import 'package:expensetrackify/config/database_config/database_service.dart';
//
// class TransactionModel {
//   final String id;
//   final String date;
//   final String mode;
//   final String category;
//   final String description;
//   final double amount;
//
//   TransactionModel({
//     required this.id,
//     required this.date,
//     required this.mode,
//     required this.category,
//     required this.description,
//     required this.amount,
//   });
//
//   factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
//     id: json['id'],
//     date: json['date'],
//     mode: json['mode'],
//     category: json['category'],
//     description: json['description'] ?? '',
//     amount: (json['amount'] as num).toDouble(),
//   );
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'date': date,
//     'mode': mode,
//     'category': category,
//     'description': description,
//     'amount': amount,
//   };
//
//   TransactionsCompanion toCompanion(int groupId) => TransactionsCompanion(
//     id: Value(id),
//     date: Value(date),
//     mode: Value(mode),
//     category: Value(category),
//     description: Value(description),
//     amount: Value(amount),
//   );
// }
//
// // Firebase-style model: ExpenseModel
// class ExpenseModel {
//   final List<String> mode;
//   final List<String> category;
//   final Map<String, TransactionModel> transaction;
//
//   ExpenseModel({
//     required this.mode,
//     required this.category,
//     required this.transaction,
//   });
//
//   factory ExpenseModel.fromJson(Map<String, dynamic> json) {
//     final Map<String, TransactionModel> txnMap = {};
//     if (json['Transaction'] != null) {
//       json['Transaction'].forEach((key, value) {
//         txnMap[key] = TransactionModel.fromJson(value);
//       });
//     }
//     return ExpenseModel(
//       mode: List<String>.from(json['mode']),
//       category: List<String>.from(json['Category']),
//       transaction: txnMap,
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'mode': mode,
//     'Category': category,
//     'Transaction': transaction.map((key, value) => MapEntry(key, value.toJson())),
//   };
// }
//
// // Firebase-style model: UserModel
// class UserModel {
//   final String uid;
//   final String name;
//   final String email;
//   final String photoUrl;
//   final bool isActive;
//   final Map<String, ExpenseModel> expenseModel;
//
//   UserModel({
//     required this.uid,
//     required this.name,
//     required this.email,
//     required this.photoUrl,
//     required this.isActive,
//     required this.expenseModel,
//   });
//
//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     final Map<String, ExpenseModel> expenseMap = {};
//     if (json['expenseModel'] != null) {
//       json['expenseModel'].forEach((key, value) {
//         expenseMap[key] = ExpenseModel.fromJson(value);
//       });
//     }
//     return UserModel(
//       uid: json['uid'],
//       name: json['name'],
//       email: json['email'],
//       photoUrl: json['photoUrl'],
//       isActive: json['isActive'],
//       expenseModel: expenseMap,
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'uid': uid,
//     'name': name,
//     'email': email,
//     'photoUrl': photoUrl,
//     'isActive': isActive,
//     'expenseModel': expenseModel.map((key, value) => MapEntry(key, value.toJson())),
//   };
// }
