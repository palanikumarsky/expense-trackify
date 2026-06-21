import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/utils/pref.dart';

import '../modules/dao/category_dao.dart';
import '../modules/dao/mode_dao.dart';

class DatabaseHelper {
  final ModeDao _modeDao = ModeDao(appDatabase);
  final CategoryDao _categoryDao = CategoryDao(appDatabase);

  /// Initialize default modes and categories
  Future<void> initializeDefaultData() async {
    try {
      // Initialize default payment modes
      await initializeDefaultModes();

      // Initialize default categories
      await initializeDefaultCategories();

    } catch (error) {
      print('Error initializing default data: $error');
    }
  }

  Future<void> initializeDefaultModes() async {
    try {
      // Get existing modes
      final existingModes = await _modeDao.getModes();

      // Define default modes
      final defaultModes = ['NetBanking', 'UPI', 'Credit Card', 'Cash'];

      // Check which default modes are missing
      final existingModeNames = existingModes.map((mode) => mode.name).toList();
      final missingModes = defaultModes.where((mode) => !existingModeNames.contains(mode)).toList();

      // Add missing modes
      for (final modeName in missingModes) {
        await _modeDao.createMode(ModesCompanion.insert(name: modeName));
        print('Added default mode: $modeName');
      }

      if (missingModes.isNotEmpty) {
        print('Initialized ${missingModes.length} default payment modes');
      }
    } catch (error) {
      print('Error initializing default modes: $error');
    }
  }

  Future<void> initializeDefaultCategories() async {
    try {
      // Get existing categories
      final existingCategories = await _categoryDao.getCategories();

      // Define default categories
      final defaultCategories = [
        'Food & Dining',
        'Transportation',
        'Shopping',
        'Entertainment',
        'Healthcare',
        'Education',
        'Bills & Utilities',
        'Travel',
        'Gifts',
        'Other'
      ];

      // Check which default categories are missing
      final existingCategoryNames = existingCategories.map((category) => category.name).toList();
      final missingCategories = defaultCategories.where((category) => !existingCategoryNames.contains(category)).toList();

      // Add missing categories
      for (final categoryName in missingCategories) {
        await _categoryDao.createCategory(CategoriesCompanion.insert(name: categoryName));
        print('Added default category: $categoryName');
      }

      if (missingCategories.isNotEmpty) {
        print('Initialized ${missingCategories.length} default categories');
      }
    } catch (error) {
      print('Error initializing default categories: $error');
    }
  }

  /// Clear all local database data (transactions, categories, modes, users)
  Future<void> clearLocalDatabaseData() async {
    try {
      // Use the centralized database service to clear all data
      await DatabaseService.clearAllData();

      // Clear sync timestamp
      await Prefs.clearLastSyncTimestamp();

      print('Local database data cleared successfully');
    } catch (error) {
      print('Error clearing local database data: $error');
      // Don't throw error to avoid breaking the sign-out flow
    }
  }
}