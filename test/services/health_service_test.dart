import 'package:aura/services/health_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthService sleep aggregation', () {
    test('sums overlapping asleep intervals once', () {
      final night = DateTime(2026, 5, 9, 22);

      final hours = HealthService.sleepHoursFromIntervals(
        asleepIntervals: [
          HealthInterval(night, night.add(const Duration(hours: 3))),
          HealthInterval(
            night.add(const Duration(hours: 1)),
            night.add(const Duration(hours: 4)),
          ),
          HealthInterval(
            night.add(const Duration(hours: 5)),
            night.add(const Duration(hours: 6)),
          ),
        ],
        inBedIntervals: const [],
      );

      expect(hours, 5);
    });

    test('uses in-bed intervals only when no asleep samples exist', () {
      final night = DateTime(2026, 5, 9, 23);

      final hours = HealthService.sleepHoursFromIntervals(
        asleepIntervals: const [],
        inBedIntervals: [
          HealthInterval(night, night.add(const Duration(hours: 7))),
        ],
      );

      expect(hours, 7);
    });

    test('returns null for empty or invalid sleep samples', () {
      final night = DateTime(2026, 5, 9, 23);

      final hours = HealthService.sleepHoursFromIntervals(
        asleepIntervals: [
          HealthInterval(night.add(const Duration(hours: 1)), night),
        ],
        inBedIntervals: const [],
      );

      expect(hours, isNull);
    });

    test('handles sleep across midnight', () {
      final start = DateTime(2026, 5, 9, 22, 30);
      final end = DateTime(2026, 5, 10, 6);

      final hours = HealthService.sleepHoursFromIntervals(
        asleepIntervals: [HealthInterval(start, end)],
        inBedIntervals: const [],
      );

      expect(hours, 7.5);
    });
  });

  group('HealthService live steps', () {
    test('normalizes pedometer boot totals to daily steps', () {
      final steps = HealthService.normalizeLiveSteps(
        seedDailySteps: 4200,
        baselineBootSteps: 125000,
        currentBootSteps: 125180,
      );

      expect(steps, 4380);
    });

    test('does not reduce daily steps when boot total moves backward', () {
      final steps = HealthService.normalizeLiveSteps(
        seedDailySteps: 4200,
        baselineBootSteps: 125000,
        currentBootSteps: 124900,
      );

      expect(steps, 4200);
    });
  });
}
