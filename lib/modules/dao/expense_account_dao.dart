import 'package:expensetrackify/config/database_config/database_service.dart';

class ExpenseAccountDao {
  final AppDatabase db;
  ExpenseAccountDao(this.db);


  Future<List<ExpensesAccount>> getExpensesAccounts() => db.select(db.expensesAccounts).get();

  Future<void> addExpenseAccount(ExpensesAccountsCompanion expenseAccount) => db.into(db.expensesAccounts).insert(expenseAccount);

  Future<void> updateExpenseAccount(ExpensesAccount expenseAccount) => db.update(db.expensesAccounts).replace(expenseAccount);

  Future<void> deleteExpenseAccount(int id) => (db.delete(db.expensesAccounts)..where((tbl) => tbl.id.equals(id))).go();

  Future<void> deleteAllExpenseAccounts() => db.delete(db.expensesAccounts).go();
}