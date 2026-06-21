import 'package:shared_preferences/shared_preferences.dart';

class DefaultSettings {
  static const String _defaultModeKey = 'default_mode';
  static const String _defaultCategoryKey = 'default_category';

  static Future<void> setDefaultMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultModeKey, mode);
  }

  static Future<String?> getDefaultMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultModeKey);
  }

  static Future<void> setDefaultCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultCategoryKey, category);
  }

  static Future<String?> getDefaultCategory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultCategoryKey);
  }
} 