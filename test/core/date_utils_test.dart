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

    test('formatTimestamp returns HH:mm', () {
      final result = AppDateUtils.formatTimestamp(DateTime(2024, 6, 15, 14, 30));
      expect(result, '14:30');
    });

    test('greeting returns time-appropriate greeting', () {
      final greeting = AppDateUtils.greeting();
      // Can't control time, but should return one of the valid strings
      expect(
        greeting,
        anyOf('Günaydın', 'İyi günler', 'İyi akşamlar'),
      );
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
