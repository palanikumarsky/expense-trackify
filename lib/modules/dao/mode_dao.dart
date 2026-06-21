import 'package:expensetrackify/config/database_config/database_service.dart';

class ModeDao {
  final AppDatabase db;
  ModeDao(this.db);

  Future<int> createMode(ModesCompanion mode) => db.into(db.modes).insert(mode);

  Future<List<Mode>> getModes() => db.select(db.modes).get();

  Future<bool> updateMode(Mode mode) => db.update(db.modes).replace(mode);

  Future<int> deleteMode(int id) => (db.delete(db.modes)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteAllModes() => db.delete(db.modes).go();
} 