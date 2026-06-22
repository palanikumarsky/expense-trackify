import 'package:intl/intl.dart';

class DateTimeHelper {
  static String getHourMinTimeMarker(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }
  String formatDate(DateTime date) {
    // Format as e.g. June 4, 2024
    return "${monthName(date.month)} ${date.day}, ${date.year}";
  }

  String getHourMin(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat.Hm().format(dateTime); // 24-hour → "13:11"
    } catch (e) {
      return "--:--"; // fallback in case of invalid input
    }
  }

  String monthName(int month) {
    const months = [
      '',
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
  String generateTransactionsId(String currentTime) {
    return currentTime.replaceAll(':', '').replaceAll('.', '').replaceAll('-', '');
  }
}
