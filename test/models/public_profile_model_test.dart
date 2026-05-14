import 'package:flutter_test/flutter_test.dart';
import 'package:aura/shared/models/public_profile_model.dart';

void main() {
  group('PublicProfileModel', () {
    test('parses public-only profile', () {
      final profile = PublicProfileModel.fromMap({
        'uid': 'uid1',
        'displayName': 'Alice',
        'currentLevel': 4,
        'currentClass': 'Novice',
        'xp': 1200,
        'streakDays': 6,
        'weeklyXp': 300,
        'relationshipStatus': 'none',
      });

      expect(profile.uid, 'uid1');
      expect(profile.isFriend, isFalse);
      expect(profile.dailyGoals, isNull);
      expect(profile.age, isNull);
    });

    test('parses friend-visible fields without body measurements', () {
      final profile = PublicProfileModel.fromMap({
        'uid': 'uid2',
        'displayName': 'Bob',
        'relationshipStatus': 'accepted',
        'age': 28,
        'dailyGoals': {'steps': 12000, 'calories': 2200, 'waterGlasses': 10},
        'socialEnergyLevel': 'Orta',
      });

      expect(profile.isFriend, isTrue);
      expect(profile.age, 28);
      expect(profile.dailyGoals?.steps, 12000);
      expect(profile.socialEnergyLevel, 'Orta');
    });
  });
}
