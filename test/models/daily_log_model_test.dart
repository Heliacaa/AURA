import 'package:flutter_test/flutter_test.dart';
import 'package:aura/shared/models/daily_log_model.dart';

void main() {
  group('DailyLogModel', () {
    test('defaults', () {
      final log = DailyLogModel(
        date: '2024-01-15',
        timestamp: DateTime(2024, 1, 15),
      );
      expect(log.stepCount, 0);
      expect(log.caloriesConsumed, 0);
      expect(log.caloriesBurned, 0);
      expect(log.waterGlasses, 0);
      expect(log.mood, '');
      expect(log.completedTasks, isEmpty);
      expect(log.dailyScore, 0);
      expect(log.xpEarned, 0);
      expect(log.mealsLogged, 0);
      expect(log.sleepHours, 0);
      expect(log.sleepQuality, '');
    });

    test('empty factory creates today log', () {
      final log = DailyLogModel.empty('2024-06-15');
      expect(log.date, '2024-06-15');
      expect(log.stepCount, 0);
      expect(log.waterGlasses, 0);
    });

    test('copyWith overrides specific fields', () {
      final log = DailyLogModel(
        date: '2024-01-15',
        timestamp: DateTime(2024, 1, 15),
        stepCount: 5000,
        waterGlasses: 4,
      );

      final updated = log.copyWith(stepCount: 10000, sleepHours: 7.5, sleepQuality: 'good');
      expect(updated.stepCount, 10000);
      expect(updated.waterGlasses, 4); // unchanged
      expect(updated.sleepHours, 7.5);
      expect(updated.sleepQuality, 'good');
      expect(updated.date, '2024-01-15'); // preserved
    });

    test('toFirestore serializes all fields', () {
      final log = DailyLogModel(
        date: '2024-01-15',
        timestamp: DateTime(2024, 1, 15),
        stepCount: 8000,
        caloriesConsumed: 1500,
        caloriesBurned: 300,
        waterGlasses: 6,
        mood: '😊',
        completedTasks: ['walk', 'study'],
        dailyScore: 85,
        xpEarned: 150,
        mealsLogged: 3,
        sleepHours: 7.0,
        sleepQuality: 'good',
      );

      final map = log.toFirestore();
      expect(map['stepCount'], 8000);
      expect(map['caloriesConsumed'], 1500);
      expect(map['caloriesBurned'], 300);
      expect(map['waterGlasses'], 6);
      expect(map['mood'], '😊');
      expect(map['completedTasks'], ['walk', 'study']);
      expect(map['dailyScore'], 85);
      expect(map['xpEarned'], 150);
      expect(map['mealsLogged'], 3);
      expect(map['sleepHours'], 7.0);
      expect(map['sleepQuality'], 'good');
    });

    test('copyWith preserves all fields when no args', () {
      final log = DailyLogModel(
        date: '2024-01-15',
        timestamp: DateTime(2024, 1, 15),
        stepCount: 5000,
        caloriesConsumed: 1200,
        waterGlasses: 5,
        mood: '😊',
        sleepHours: 8.0,
        sleepQuality: 'good',
      );

      final copy = log.copyWith();
      expect(copy.stepCount, 5000);
      expect(copy.caloriesConsumed, 1200);
      expect(copy.waterGlasses, 5);
      expect(copy.mood, '😊');
      expect(copy.sleepHours, 8.0);
      expect(copy.sleepQuality, 'good');
    });
  });
}
