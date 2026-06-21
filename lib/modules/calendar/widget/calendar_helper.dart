import 'package:intl/intl.dart';

class CalendarHelper {
  /// Get the number of days in a month
  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  /// Get the first day of the month
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get the last day of the month
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Get the weekday of the first day of the month (0 = Sunday, 1 = Monday, etc.)
  static int getFirstWeekdayOfMonth(DateTime date) {
    return getFirstDayOfMonth(date).weekday % 7;
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  /// Format date for display
  static String formatDate(DateTime date, String pattern) {
    return DateFormat(pattern).format(date);
  }

  /// Get month name
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  /// Get year
  static int getYear(DateTime date) {
    return date.year;
  }

  /// Get month
  static int getMonth(DateTime date) {
    return date.month;
  }

  /// Get day
  static int getDay(DateTime date) {
    return date.day;
  }

  /// Get previous month
  static DateTime getPreviousMonth(DateTime date) {
    return DateTime(date.year, date.month - 1);
  }

  /// Get next month
  static DateTime getNextMonth(DateTime date) {
    return DateTime(date.year, date.month + 1);
  }

  /// Get days of week names
  static List<String> getDaysOfWeek() {
    return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  }

  /// Get days of week names with full names
  static List<String> getFullDaysOfWeek() {
    return ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  }
} 