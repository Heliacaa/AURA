import 'package:flutter_test/flutter_test.dart';
import 'package:aura/shared/models/achievement_model.dart';

void main() {
  group('AchievementModel', () {
    test('toFirestore serializes all fields', () {
      final achievement = AchievementModel(
        id: 'first_scan',
        title: 'İlk Tarama',
        description: 'İlk yemek taramanı yaptın!',
        unlockedAt: DateTime(2024, 6, 15),
        icon: '📸',
      );

      final map = achievement.toFirestore();
      expect(map['id'], 'first_scan');
      expect(map['title'], 'İlk Tarama');
      expect(map['description'], 'İlk yemek taramanı yaptın!');
      expect(map['icon'], '📸');
    });

    test('constructor sets all fields', () {
      final achievement = AchievementModel(
        id: 'streak_7',
        title: '7 Day Streak',
        description: 'Logged in 7 days in a row',
        unlockedAt: DateTime(2024, 1, 1),
        icon: '🔥',
      );

      expect(achievement.id, 'streak_7');
      expect(achievement.title, '7 Day Streak');
      expect(achievement.icon, '🔥');
    });
  });
}
