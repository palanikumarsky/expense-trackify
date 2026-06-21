import 'package:drift/drift.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';

class UserDao {
  final AppDatabase _db;
  
  UserDao(this._db);

  // Get all users
  Future<List<User>> getAllUsers() => _db.select(_db.users).get();

  // Get user by email
  Future<User?> getUserByEmail(String email) =>
      (_db.select(_db.users)..where((u) => u.emailId.equals(email))).getSingleOrNull();

  // Get user by ID
  Future<User?> getUserById(int id) =>
      (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingleOrNull();

  // Insert new user
  Future<int> insertUser(UsersCompanion user) => _db.into(_db.users).insert(user);

  // Update user
  Future<bool> updateUser(UsersCompanion user) =>
      _db.update(_db.users).replace(user);

  // Delete user
  Future<int> deleteUser(int id) =>
      (_db.delete(_db.users)..where((u) => u.id.equals(id))).go();

  // Delete all users
  Future<int> deleteAllUsers() => _db.delete(_db.users).go();

  // Insert or update user (upsert)
  Future<void> upsertUser(UsersCompanion user) async {
    final existingUser = await getUserByEmail(user.emailId.value);
    if (existingUser != null) {
      // Update existing user
      await updateUser(user.copyWith(id: Value(existingUser.id)));
    } else {
      // Insert new user
      await insertUser(user);
    }
  }

  // Create user companion from user data
  UsersCompanion createUserCompanion({
    required String name,
    required String emailId,
    String? photoUrl,
  }) {
    final now = DateTime.now().toIso8601String();
    return UsersCompanion(
      name: Value(name),
      emailId: Value(emailId),
      photoUrl: Value(photoUrl),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }
} 