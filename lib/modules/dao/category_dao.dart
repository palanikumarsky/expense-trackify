import 'package:expensetrackify/config/database_config/database_service.dart';

class CategoryDao {
  final AppDatabase db;
  CategoryDao(this.db);

  Future<int> createCategory(CategoriesCompanion category) => db.into(db.categories).insert(category);

  Future<List<Category>> getCategories() => db.select(db.categories).get();

  Future<bool> updateCategory(Category category) => db.update(db.categories).replace(category);

  Future<int> deleteCategory(int id) => (db.delete(db.categories)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteAllCategories() => db.delete(db.categories).go();
} 