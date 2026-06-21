import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:drift/drift.dart';

class TransactionDao {
  final AppDatabase db;
  TransactionDao(this.db);

  Future<int> createTransaction(TransactionsCompanion transaction) => db.into(db.transactions).insert(transaction);

  Future<List<TransactionWithDetails>> getTransactions({int selectedAccountId = 0}) {
    final query = db.select(db.transactions).join([
      leftOuterJoin(db.modes, db.modes.id.equalsExp(db.transactions.modeId)),
      leftOuterJoin(db.categories, db.categories.id.equalsExp(db.transactions.categoryId)),
    ]);

    // Only apply filter if selectedAccountId is not 0
    if (selectedAccountId != 0) {
      query.where(db.transactions.expensesAccountId.equals(selectedAccountId));
    }

    return query.map((row) => TransactionWithDetails(
      transaction: row.readTable(db.transactions),
      mode: row.readTableOrNull(db.modes),
      category: row.readTableOrNull(db.categories),
    )).get();
  }

  Future<List<Transaction>> getUnsyncedTransactions() {
    return (db.select(db.transactions)..where((tbl) => tbl.isSynced.equals(false))).get();
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Convert dates to string format for comparison with text column
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    final query = (db.select(db.transactions)..where((tbl) => 
      tbl.date.isBiggerOrEqualValue(startDateStr) & 
      tbl.date.isSmallerOrEqualValue(endDateStr)
    )).join([
      leftOuterJoin(db.modes, db.modes.id.equalsExp(db.transactions.modeId)),
      leftOuterJoin(db.categories, db.categories.id.equalsExp(db.transactions.categoryId)),
    ]);
    
    final queryResults = await query.get();
    
    final results = queryResults.map((row) => {
      'id': row.readTable(db.transactions).id,
      'amount': row.readTable(db.transactions).amount,
      'description': row.readTable(db.transactions).description,
      'date': row.readTable(db.transactions).date,
      'mode': row.readTableOrNull(db.modes)?.name ?? 'Unknown',
      'category': row.readTableOrNull(db.categories)?.name ?? 'Unknown',
    }).toList();
    
    return results;
  }

  Future<bool> updateTransaction(Transaction transaction) => db.update(db.transactions).replace(transaction);

  Future<int> deleteTransaction(String id) => (db.delete(db.transactions)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteAllTransactions() => db.delete(db.transactions).go();
}

class TransactionWithDetails {
  final Transaction transaction;
  final Mode? mode;
  final Category? category;
  TransactionWithDetails({required this.transaction, this.mode, this.category});
} 