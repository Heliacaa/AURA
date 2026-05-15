import 'package:flutter_test/flutter_test.dart';
import 'package:aura/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    test('todayKey returns yyyy-MM-dd format', () {
      final key = AppDateUtils.todayKey();
      expect(key, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });

    test('formatDate formats correctly', () {
      final result = AppDateUtils.formatDate(DateTime(2024, 1, 5));
      expect(result, '2024-01-05');
    });

    test('formatDate handles month/day padding', () {
      expect(AppDateUtils.formatDate(DateTime(2024, 12, 25)), '2024-12-25');
      expect(AppDateUtils.formatDate(DateTime(2024, 1, 1)), '2024-01-01');
    });

    test('formatDayMonthYear returns dd/MM/yyyy', () {
      expect(
        AppDateUtils.formatDayMonthYear(DateTime(2026, 5, 14)),
        '14/05/2026',
      );
    });

    test('formatTimestamp returns HH:mm', () {
      final result = AppDateUtils.formatTimestamp(
        DateTime(2024, 6, 15, 14, 30),
      );
      expect(result, '14:30');
    });

    test('weekKey uses Monday-start ISO week format', () {
      expect(AppDateUtils.weekKey(DateTime(2026, 5, 3)), '2026-W18');
      expect(AppDateUtils.weekKey(DateTime(2026, 5, 4)), '2026-W19');
      expect(AppDateUtils.weekKey(DateTime(2024, 12, 30)), '2025-W01');
    });

    test('startOfIsoWeek and endOfIsoWeek return Monday and Sunday', () {
      final date = DateTime(2026, 5, 15);

      expect(AppDateUtils.startOfIsoWeek(date), DateTime(2026, 5, 11));
      expect(AppDateUtils.endOfIsoWeek(date), DateTime(2026, 5, 17));
    });

    test('greeting returns time-appropriate greeting', () {
      final greeting = AppDateUtils.greeting();
      // Can't control time, but should return one of the valid strings
      expect(greeting, anyOf('Günaydın', 'İyi günler', 'İyi akşamlar'));
    });

    test('isToday returns true for today', () {
      expect(AppDateUtils.isToday(DateTime.now()), isTrue);
    });

    test('isToday returns false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppDateUtils.isToday(yesterday), isFalse);
    });

    test('isYesterday returns true for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppDateUtils.isYesterday(yesterday), isTrue);
    });

    test('isYesterday returns false for today', () {
      expect(AppDateUtils.isYesterday(DateTime.now()), isFalse);
    });

    test('isYesterday returns false for two days ago', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      expect(AppDateUtils.isYesterday(twoDaysAgo), isFalse);
    });
  });
}
