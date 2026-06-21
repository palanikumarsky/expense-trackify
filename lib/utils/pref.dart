import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/utils/preference_helper.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class Prefs {
  // --- Theme Management ---
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

  static Future<void> loadTheme() async {
    final themeString = await PreferencesHelper.getString('theme_mode');
    if (themeString.isNotEmpty) {
      themeModeNotifier.value = ThemeMode.values.firstWhere(
        (e) => e.toString().split('.').last == themeString,
        orElse: () => ThemeMode.system,
      );
    }
  }

  static Future<void> setTheme(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    await PreferencesHelper.setString('theme_mode', mode.toString().split('.').last);
  }

  // --- Currency Management ---
  static final ValueNotifier<String> currencyCodeNotifier = ValueNotifier('USD');

  static Future<void> loadCurrency() async {
    final code = await PreferencesHelper.getString('currency_code');
    currencyCodeNotifier.value = code.isNotEmpty ? code : 'USD';
  }

  static Future<void> setCurrency(String code) async {
    currencyCodeNotifier.value = code;
    await PreferencesHelper.setString('currency_code', code);
  }

  // --- Existing user methods ---
  static const String _guestUserStatusKey = 'guest_user_status';
  static const String _userEmailKey = 'user_email';
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';
  static const String _currencyCodeKey = 'currency_code';

  // Stream controller for user type changes
  static final StreamController<String> _userTypeController = StreamController<String>.broadcast();
  static Stream<String> get userTypeStream => _userTypeController.stream;

  // Stream controller for guest status changes
  static final StreamController<bool> _guestStatusController = StreamController<bool>.broadcast();
  static Stream<bool> get guestStatusStream => _guestStatusController.stream;

  // Current values cache
  static String? _currentUserType;
  static bool? _currentGuestStatus;

  // Guest user status
  static Future<bool> get getGuestUserStatus async {
    return PreferencesHelper.getBool(_guestUserStatusKey);
  }

  static Future<void> setGuestUserStatus(bool status) async {
    await PreferencesHelper.setBool(_guestUserStatusKey, status);
    
    // Update cache and emit if changed
    if (_currentGuestStatus != status) {
      _currentGuestStatus = status;
      _guestStatusController.add(status);
    }
  }

  // User email
  static Future<String?> get getUserEmail async {
    return PreferencesHelper.getString(_userEmailKey);
  }

  static Future<void> setUserEmail(String email) async {
    await PreferencesHelper.setString(_userEmailKey, email);
  }

  static Future<void> removeUserEmail() async {
    await PreferencesHelper.removeString(_userEmailKey);
  }

  // User email
  static Future<String?> get getUserType async {
    return PreferencesHelper.getString(AppConstants.userType);
  }

  static Future<void> setUserType(String userType) async {
    await PreferencesHelper.setString(AppConstants.userType, userType);
  }

  static Future<void> removeUserType() async {
    await PreferencesHelper.removeString(AppConstants.userType);
  }

  // Last sync timestamp
  static Future<String?> get getLastSyncTimestamp async {
    return PreferencesHelper.getString(_lastSyncTimestampKey);
  }

  static Future<void> setLastSyncTimestamp() async {
    final timestamp = DateTime.now().toIso8601String();
    await PreferencesHelper.setString(_lastSyncTimestampKey, timestamp);
  }

  static Future<void> clearLastSyncTimestamp() async {
    await PreferencesHelper.removeString(_lastSyncTimestampKey);
  }

  // Select Category
  static Future<String?> get getSelectedCategory async {
    return PreferencesHelper.getString(AppConstants.selectedCategory);
  }

  static Future<void> setSelectedCategory(String selectedCategory) async {
    await PreferencesHelper.setString(AppConstants.selectedCategory, selectedCategory);
  }

  static Future<void> removeSelectedCategory() async {
    await PreferencesHelper.removeString(AppConstants.selectedCategory);
  }

  // Select PaymentMode
  static Future<String?> get getSelectedPaymentMode async {
    return PreferencesHelper.getString(AppConstants.selectedPaymentMode);
  }

  static Future<void> setSelectedPaymentMode(String selectedPaymentMode) async {
    await PreferencesHelper.setString(AppConstants.selectedPaymentMode, selectedPaymentMode);
  }

  static Future<void> removeSelectedPaymentMode() async {
    await PreferencesHelper.removeString(AppConstants.selectedPaymentMode);
  }

  // Selected Account
  static Future<String?> get getSelectedAccount async {
    return PreferencesHelper.getString(AppConstants.selectedAccount);
  }

  static Future<void> setSelectedAccount(String selectedAccount) async {
    await PreferencesHelper.setString(AppConstants.selectedAccount, selectedAccount);
  }

  static Future<void> removeSelectedAccount() async {
    await PreferencesHelper.removeString(AppConstants.selectedAccount);
  }

  static Future<void> clear() => PreferencesHelper.clearPreference();
}
