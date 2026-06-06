import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/shared/models/user_model.dart';

void main() {
  group('UserStats', () {
    test('defaults to zeroes', () {
      const stats = UserStats();
      expect(stats.strength, 0);
      expect(stats.intelligence, 0);
      expect(stats.charisma, 0);
      expect(stats.vitality, 0);
    });

    test('fromMap parses correctly', () {
      final stats = UserStats.fromMap({
        'strength': 10,
        'intelligence': 20,
        'charisma': 30,
        'vitality': 40,
      });
      expect(stats.strength, 10);
      expect(stats.intelligence, 20);
      expect(stats.charisma, 30);
      expect(stats.vitality, 40);
    });

    test('fromMap handles null and missing values', () {
      final stats = UserStats.fromMap({'strength': null});
      expect(stats.strength, 0);
      expect(stats.intelligence, 0);
    });

    test('toMap round-trips', () {
      const stats = UserStats(
        strength: 5,
        intelligence: 10,
        charisma: 15,
        vitality: 20,
      );
      final map = stats.toMap();
      final restored = UserStats.fromMap(map);
      expect(restored.strength, 5);
      expect(restored.intelligence, 10);
      expect(restored.charisma, 15);
      expect(restored.vitality, 20);
    });

    test('copyWith overrides fields', () {
      const stats = UserStats(strength: 1, intelligence: 2);
      final updated = stats.copyWith(strength: 99);
      expect(updated.strength, 99);
      expect(updated.intelligence, 2);
    });
  });

  group('DailyGoals', () {
    test('defaults', () {
      const goals = DailyGoals();
      expect(goals.steps, 10000);
      expect(goals.calories, 2000);
      expect(goals.waterGlasses, 8);
    });

    test('fromMap and toMap round-trip', () {
      const goals = DailyGoals(steps: 15000, calories: 2500, waterGlasses: 10);
      final map = goals.toMap();
      final restored = DailyGoals.fromMap(map);
      expect(restored.steps, 15000);
      expect(restored.calories, 2500);
      expect(restored.waterGlasses, 10);
    });

    test('fromMap handles missing values', () {
      final goals = DailyGoals.fromMap({});
      expect(goals.steps, 10000);
      expect(goals.calories, 2000);
      expect(goals.waterGlasses, 8);
    });

    test('copyWith overrides selected goals', () {
      const goals = DailyGoals(steps: 10000, calories: 2000, waterGlasses: 8);
      final updated = goals.copyWith(calories: 1800);
      expect(updated.steps, 10000);
      expect(updated.calories, 1800);
      expect(updated.waterGlasses, 8);
    });
  });

  group('UserModel', () {
    late UserModel user;

    setUp(() {
      user = UserModel(
        uid: 'test-uid',
        displayName: 'Test User',
        email: 'test@example.com',
        createdAt: DateTime(2024, 1, 1),
        lastActiveDate: DateTime(2024, 6, 1),
        age: 29,
        heightCm: 178,
        weightKg: 74.5,
        currentLevel: 5,
        currentClass: 'Warrior',
        xp: 5000,
        xpToNextLevel: 10000,
        streakDays: 7,
        stats: const UserStats(
          strength: 10,
          intelligence: 20,
          charisma: 5,
          vitality: 15,
        ),
        dailyGoals: const DailyGoals(
          steps: 12000,
          calories: 2200,
          waterGlasses: 10,
        ),
        socialEnergyLevel: 'Yüksek',
        leaderboardOptIn: true,
        weeklyXp: 320,
        weeklyXpWeek: '2026-W18',
        shareMilestones: false,
        lastSocialFeedReadAt: DateTime(2026, 6, 4, 12),
      );
    });

    test('classIcon returns correct emoji', () {
      expect(user.classIcon, '🛡️');
      expect(user.copyWith(currentClass: 'Novice').classIcon, '🌱');
      expect(user.copyWith(currentClass: 'Mage').classIcon, '🧙');
      expect(user.copyWith(currentClass: 'Champion').classIcon, '⚔️');
      expect(user.copyWith(currentClass: 'Legend').classIcon, '👑');
      expect(user.copyWith(currentClass: 'Unknown').classIcon, '🌱');
    });

    test('leaderboard defaults are private and empty', () {
      final model = UserModel(
        uid: 'u1',
        displayName: 'Private User',
        email: 'private@test.com',
        createdAt: DateTime(2024, 1, 1),
        lastActiveDate: DateTime(2024, 1, 1),
      );

      expect(model.leaderboardOptIn, isFalse);
      expect(model.weeklyXp, 0);
      expect(model.weeklyXpWeek, '');
    });

    test('classForLevel returns correct class', () {
      expect(UserModel.classForLevel(1), 'Novice');
      expect(UserModel.classForLevel(4), 'Novice');
      expect(UserModel.classForLevel(5), 'Warrior');
      expect(UserModel.classForLevel(9), 'Warrior');
      expect(UserModel.classForLevel(10), 'Mage');
      expect(UserModel.classForLevel(19), 'Mage');
      expect(UserModel.classForLevel(20), 'Champion');
      expect(UserModel.classForLevel(34), 'Champion');
      expect(UserModel.classForLevel(35), 'Legend');
      expect(UserModel.classForLevel(100), 'Legend');
    });

    test('xpForLevel returns thresholds', () {
      expect(UserModel.xpForLevel(0), 0);
      expect(UserModel.xpForLevel(1), 500);
      expect(UserModel.xpForLevel(34), 2910000);
      // Beyond thresholds
      expect(UserModel.xpForLevel(35), 2910000 + 200000);
      // Negative
      expect(UserModel.xpForLevel(-1), 0);
    });

    test('levelThresholds has 35 entries', () {
      expect(UserModel.levelThresholds.length, 35);
    });

    test('copyWith works correctly', () {
      final updated = user.copyWith(displayName: 'New Name', xp: 9999);
      expect(updated.displayName, 'New Name');
      expect(updated.xp, 9999);
      expect(updated.uid, 'test-uid');
      expect(updated.email, 'test@example.com');
      expect(updated.age, 29);
      expect(updated.heightCm, 178);
      expect(updated.weightKg, 74.5);
    });

    test('copyWith can clear optional private profile fields', () {
      final updated = user.copyWith(age: null, heightCm: null, weightKg: null);
      expect(updated.age, isNull);
      expect(updated.heightCm, isNull);
      expect(updated.weightKg, isNull);
    });

    test('toFirestore serializes correctly', () {
      final map = user.toFirestore();
      expect(map['displayName'], 'Test User');
      expect(map['email'], 'test@example.com');
      expect(map['emailLower'], 'test@example.com');
      expect(map['age'], 29);
      expect(map['heightCm'], 178);
      expect(map['weightKg'], 74.5);
      expect(map['currentLevel'], 5);
      expect(map['currentClass'], 'Warrior');
      expect(map['xp'], 5000);
      expect(map['streakDays'], 7);
      expect(map['leaderboardOptIn'], isTrue);
      expect(map['weeklyXp'], 320);
      expect(map['weeklyXpWeek'], '2026-W18');
      expect(map['shareMilestones'], isFalse);
      expect(
        (map['lastSocialFeedReadAt'] as Timestamp).toDate(),
        DateTime(2026, 6, 4, 12),
      );
      expect(map['stats']['strength'], 10);
      expect(map['dailyGoals']['steps'], 12000);
    });

    test('social preferences use safe defaults', () {
      final model = UserModel(
        uid: 'u1',
        displayName: 'Default Social Preferences',
        email: 'defaults@test.com',
        createdAt: DateTime(2024, 1, 1),
        lastActiveDate: DateTime(2024, 1, 1),
      );
      final map = model.toFirestore();
      expect(map['shareMilestones'], isTrue);
    });
  });
}
