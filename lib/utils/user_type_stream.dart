import 'dart:async';
import 'package:expensetrackify/utils/preference_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expensetrackify/constants/app_constants.dart';

class UserTypeStream {
  static final UserTypeStream _instance = UserTypeStream._internal();
  factory UserTypeStream() => _instance;
  UserTypeStream._internal();

  // Stream controller for user type
  final StreamController<String> _userTypeController = StreamController<String>.broadcast();
  final StreamController<UserTypeChange> _userTypeChangeController = StreamController<UserTypeChange>.broadcast();

  // Stream
  Stream<String> get userTypeStream => _userTypeController.stream;
  Stream<UserTypeChange> get userTypeChangeStream => _userTypeChangeController.stream;

  // Current value cache
  String? _currentUserType;

  // Keys
  static const String _userTypeKey = 'user_type';

  /// Initialize the stream service with current value
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserType = prefs.getString(_userTypeKey) ?? AppConstants.guest;
    // Emit initial value
    _userTypeController.add(_currentUserType!);
  }

  /// Get current user type
  Future<String> getCurrentUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey) ?? AppConstants.guest;
  }

  /// Set user type and emit stream
  Future<void> setUserType(String userType) async {
    await PreferencesHelper.setString(_userTypeKey, userType);
    // Update cache and emit if changed
    if (_currentUserType != userType) {
      final previousUserType = _currentUserType;
      _currentUserType = userType;
      _userTypeController.add(userType);
      // Emit change event
      _userTypeChangeController.add(UserTypeChange(
        previousUserType: previousUserType ?? AppConstants.guest,
        currentUserType: userType,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Update user type
  Future<void> updateUserType(String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTypeKey, userType);
    final previousUserType = _currentUserType;
    _currentUserType = userType;
    _userTypeController.add(userType);
    if (previousUserType != userType) {
      _userTypeChangeController.add(UserTypeChange(
        previousUserType: previousUserType ?? AppConstants.guest,
        currentUserType: userType,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Check if user is currently authenticated
  bool get isAuthenticated => _currentUserType == AppConstants.loggedUser;

  /// Get current user type (synchronous)
  String get currentUserType => _currentUserType ?? AppConstants.guest;

  /// Listen to user type changes with a callback
  StreamSubscription<String> listenToUserTypeChanges(Function(String) onChanged) {
    return userTypeStream.listen(onChanged);
  }

  /// Listen to user type changes with detailed information
  StreamSubscription<UserTypeChange> listenToUserTypeChangesDetailed(Function(UserTypeChange) onChanged) {
    return userTypeChangeStream.listen(onChanged);
  }

  /// Dispose all streams
  void dispose() {
    _userTypeController.close();
    _userTypeChangeController.close();
  }

  /// Example: Listen to authentication state changes
  StreamSubscription<bool> listenToAuthenticationChanges(Function(bool) onAuthenticated) {
    return userTypeStream.map((userType) => userType == AppConstants.loggedUser).listen(onAuthenticated);
  }

  /// Example: Get a stream that emits when user becomes authenticated
  Stream<String> get onUserAuthenticated {
    return userTypeStream.where((userType) => userType == AppConstants.loggedUser);
  }

  /// Example: Get a stream that emits when user becomes a guest
  Stream<String> get onUserBecomesGuest {
    return userTypeStream.where((userType) => userType == AppConstants.guest);
  }

  /// Example: Check if user is authenticated (synchronous)
  bool get isUserAuthenticated => _currentUserType == AppConstants.loggedUser;
  /// Example: Check if user is guest (synchronous)
  bool get isUserGuest => _currentUserType == AppConstants.guest;
}

/// Data class for user type change events
class UserTypeChange {
  final String previousUserType;
  final String currentUserType;
  final DateTime timestamp;

  UserTypeChange({
    required this.previousUserType,
    required this.currentUserType,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'UserTypeChange(previous: $previousUserType, current: $currentUserType, timestamp: $timestamp)';
  }
}

// Global instance
final userTypeStream = UserTypeStream(); 