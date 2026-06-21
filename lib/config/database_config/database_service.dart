import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
part 'database_service.g.dart';

// Table definitions
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get emailId => text().unique()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
}

class Modes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  IntColumn get modeId => integer().customConstraint('REFERENCES modes(id) NOT NULL')();
  IntColumn get categoryId => integer().customConstraint('REFERENCES categories(id) NOT NULL')();
  IntColumn get expensesAccountId => integer().nullable().references(ExpensesAccounts, #id)();
  TextColumn get date => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

class ExpensesAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'transactions.db'));
    return NativeDatabase(file);
  });
}

@DriftDatabase(tables: [Users, Modes, Categories, Transactions, ExpensesAccounts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Create the Users table when upgrading from version 1 to 2
          await m.createTable(users);
        }
        if (from < 3) {
          // Add the isSynced column to the Transactions table when upgrading from version 2 to 3
          await m.addColumn(transactions, transactions.isSynced);
          // Note: Primary key addition is handled automatically by Drift
        }
        if (from < 4) {
          await m.createTable(expensesAccounts);
          await m.deleteTable('app_settings');
        }
        if (from < 6) {
          // Add the expensesAccountId column to the Transactions table
          await m.addColumn(transactions, transactions.expensesAccountId);
        }
      },
    );
  }
}

// Global database instance - singleton pattern
class DatabaseService {
  static AppDatabase? _instance;
  
  static AppDatabase get instance {
    _instance ??= AppDatabase();
    return _instance!;
  }
  
  // Method to close the database (useful for testing or app shutdown)
  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
  
  // Method to clear all data from the database
  static Future<void> clearAllData() async {
    final db = instance;
    await db.delete(db.transactions).go();
    await db.delete(db.categories).go();
    await db.delete(db.modes).go();
    await db.delete(db.users).go();
    await db.delete(db.expensesAccounts).go();
  }
  
  // Method to get database statistics
  static Future<Map<String, int>> getDatabaseStats() async {
    final db = instance;
    final transactionCount = await db.select(db.transactions).get().then((list) => list.length);
    final categoryCount = await db.select(db.categories).get().then((list) => list.length);
    final modeCount = await db.select(db.modes).get().then((list) => list.length);
    final userCount = await db.select(db.users).get().then((list) => list.length);
    final expensesAccountCount = await db.select(db.expensesAccounts).get().then((list) => list.length);
    
    return {
      'transactions': transactionCount,
      'categories': categoryCount,
      'modes': modeCount,
      'users': userCount,
      'expensesAccounts': expensesAccountCount,
    };
  }
}

// Global variable for easy access
final appDatabase = DatabaseService.instance; 