import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/shared/models/public_profile_model.dart';

void main() {
  group('PublicProfileModel', () {
    test('fromFirestore parses public fields', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('publicProfiles').doc('uid1').set({
        'uid': 'uid1',
        'displayName': 'Alice',
        'email': 'Alice@Test.com',
        'emailLowercase': 'alice@test.com',
        'avatarUrl': 'https://example.com/a.png',
        'currentLevel': 4,
        'currentClass': 'Warrior',
        'xp': 1200,
        'streakDays': 8,
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      final doc = await firestore
          .collection('publicProfiles')
          .doc('uid1')
          .get();
      final profile = PublicProfileModel.fromFirestore(doc);

      expect(profile.uid, 'uid1');
      expect(profile.displayName, 'Alice');
      expect(profile.emailLowercase, 'alice@test.com');
      expect(profile.currentLevel, 4);
      expect(profile.streakDays, 8);
    });

    test('toFirestore serializes only public profile fields', () {
      final profile = PublicProfileModel(
        uid: 'uid2',
        displayName: 'Bob',
        email: 'bob@test.com',
        emailLowercase: 'bob@test.com',
        avatarUrl: 'https://example.com/b.png',
        currentLevel: 2,
        xp: 400,
        streakDays: 3,
        updatedAt: DateTime(2024, 2, 1),
      );

      final map = profile.toFirestore();
      expect(map['uid'], 'uid2');
      expect(map['displayName'], 'Bob');
      expect(map['email'], 'bob@test.com');
      expect(map['avatarUrl'], 'https://example.com/b.png');
      expect(map.containsKey('dailyGoals'), isFalse);
      expect(map.containsKey('fcmToken'), isFalse);
    });
  });
}
