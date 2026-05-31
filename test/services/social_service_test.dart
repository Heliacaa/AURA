import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura/services/social_service.dart';

void main() {
  group('SocialService', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late SocialService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid1', displayName: 'Alice'),
        signedIn: true,
      );
      service = SocialService(firestore: firestore, auth: auth);
    });

    test('activity stream hides legacy mock users', () async {
      final activities = firestore.collection('social_activities');
      await activities.doc('legacy').set({
        'userId': 'mock_user_1',
        'userName': 'Ahmet',
        'actionTitle': 'Mock',
        'timestamp': Timestamp.fromDate(DateTime(2026, 5, 1, 10)),
        'likes': [],
      });
      await activities.doc('real').set({
        'userId': 'uid1',
        'userName': 'Alice',
        'actionTitle': 'Gerçek aktivite',
        'timestamp': Timestamp.fromDate(DateTime(2026, 5, 1, 11)),
        'likes': [],
      });

      final visible = await service.getActivitiesStream().first;

      expect(visible.map((item) => item.id), ['real']);
    });

    test('default social data cleans old mock activities', () async {
      await firestore.collection('social_activities').doc('legacy').set({
        'userId': 'mock_user_1',
        'userName': 'Ahmet',
        'actionTitle': 'Mock',
        'timestamp': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'likes': [],
      });

      await service.ensureDefaultSocialData();

      final challengeDocs = await firestore
          .collection('social_challenges')
          .get();
      final activityDocs = await firestore
          .collection('social_activities')
          .get();

      expect(challengeDocs.docs.length, 2);
      expect(activityDocs.docs, isEmpty);
    });

    test('publishes achievement activity with public profile data', () async {
      await firestore.collection('publicProfiles').doc('uid1').set({
        'displayName': 'Alice',
        'avatarUrl': 'https://example.com/a.png',
      });

      await service.publishAchievementActivity(
        activityId: 'achievement_uid1_first_quest',
        uid: 'uid1',
        achievementTitle: 'İlk Görev',
        achievementDescription: 'İlk görev ödülünü aldın.',
        achievementIcon: '🎯',
      );

      final doc = await firestore
          .collection('social_activities')
          .doc('achievement_uid1_first_quest')
          .get();
      final data = doc.data();

      expect(data?['userId'], 'uid1');
      expect(data?['userName'], 'Alice');
      expect(data?['userAvatarUrl'], 'https://example.com/a.png');
      expect(data?['actionTitle'], '🎯 İlk Görev Rozeti');
    });
  });
}
