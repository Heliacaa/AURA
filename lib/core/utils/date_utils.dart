import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String todayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatTimestamp(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatFullDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'tr_TR').format(date);
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}
