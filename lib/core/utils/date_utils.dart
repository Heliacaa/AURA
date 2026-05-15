import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String todayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static String weekKey([DateTime? date]) {
    final localDate = date ?? DateTime.now();
    final day = DateTime(localDate.year, localDate.month, localDate.day);
    final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
    final firstThursdaySeed = DateTime(thursday.year, 1, 4);
    final firstThursday = firstThursdaySeed.add(
      Duration(days: DateTime.thursday - firstThursdaySeed.weekday),
    );
    final weekNumber = 1 + thursday.difference(firstThursday).inDays ~/ 7;

    return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  static DateTime startOfIsoWeek([DateTime? date]) {
    final localDate = date ?? DateTime.now();
    final day = DateTime(localDate.year, localDate.month, localDate.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static DateTime endOfIsoWeek([DateTime? date]) {
    return startOfIsoWeek(date).add(const Duration(days: 6));
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
