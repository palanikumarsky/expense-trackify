// import 'package:expensetrackify/config/database_config/database_service.dart';
// import 'package:drift/drift.dart';
// import 'dart:convert';
//
// class AppSettingsDao {
//   final AppDatabase db;
//   AppSettingsDao(this.db);
//
//   Future<String?> getSelectedModelName() async {
//     final settings = await db.select(db.appSettings).get();
//     if (settings.isNotEmpty) {
//       return settings.first.selectedModelName;
//     }
//     return null;
//   }
//
//   Future<void> setSelectedModelName(String modelName) async {
//     final settings = await db.select(db.appSettings).get();
//     if (settings.isEmpty) {
//       // Insert new row
//       await db.into(db.appSettings).insert(AppSettingsCompanion(selectedModelName: Value(modelName)));
//     } else {
//       // Update existing row (assume only one row)
//       final row = settings.first;
//       await (db.update(db.appSettings)..where((tbl) => tbl.id.equals(row.id))).write(AppSettingsCompanion(selectedModelName: Value(modelName)));
//     }
//   }
//
//   Future<List<String>> getAllModelNames() async {
//     final settings = await db.select(db.appSettings).get();
//     if (settings.isNotEmpty && settings.first.allModelNames != null) {
//       final jsonStr = settings.first.allModelNames!;
//       final List<dynamic> decoded = json.decode(jsonStr);
//       return decoded.cast<String>();
//     }
//     return [];
//   }
//
//   Future<void> setAllModelNames(List<String> modelNames) async {
//     final jsonStr = json.encode(modelNames);
//     final settings = await db.select(db.appSettings).get();
//     if (settings.isEmpty) {
//       await db.into(db.appSettings).insert(AppSettingsCompanion(allModelNames: Value(jsonStr)));
//     } else {
//       final row = settings.first;
//       await (db.update(db.appSettings)..where((tbl) => tbl.id.equals(row.id))).write(AppSettingsCompanion(allModelNames: Value(jsonStr)));
//     }
//   }
//   Future<void> createNewModel(String modelName) async {
//     final settings = await db.select(db.appSettings).get();
//     if (settings.isEmpty) {
//       await db.into(db.appSettings).insert(AppSettingsCompanion(allModelNames: Value(json.encode([modelName]))));
//     } else {
//       final row = settings.first;
//       await (db.update(db.appSettings)..where((tbl) => tbl.id.equals(row.id))).write(AppSettingsCompanion(allModelNames: Value(json.encode([modelName]))));
//     }
//   }
// }