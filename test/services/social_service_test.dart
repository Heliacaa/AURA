import 'package:aura/core/utils/date_utils.dart';
import 'package:aura/services/social_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SocialService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = SocialService(
      firestore: firestore,
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'u1'), signedIn: true),
    );
  });

  Future<void> seedActivity(
    String id, {
    required String actorUid,
    required String visibility,
    required DateTime createdAt,
  }) {
    return firestore.collection('social_activities').doc(id).set({
      'type': visibility == 'global'
          ? 'community_challenge_completed'
          : 'streak_milestone',
      'actorUid': actorUid,
      'actorDisplayName': actorUid.isEmpty ? 'AURA' : actorUid,
      'actorAvatarUrl': '',
      'title': id,
      'description': '',
      'metadata': {},
      'visibility': visibility,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSpecialAchievement': false,
    });
  }

  test('feed merges global, own, and current-friend activities only', () async {
    await seedActivity(
      'global',
      actorUid: '',
      visibility: 'global',
      createdAt: DateTime(2026, 6, 4, 10),
    );
    await seedActivity(
      'friend',
      actorUid: 'u2',
      visibility: 'friends',
      createdAt: DateTime(2026, 6, 4, 12),
    );
    await seedActivity(
      'own',
      actorUid: 'u1',
      visibility: 'friends',
      createdAt: DateTime(2026, 6, 4, 11),
    );
    await seedActivity(
      'stranger',
      actorUid: 'u3',
      visibility: 'friends',
      createdAt: DateTime(2026, 6, 4, 13),
    );

    final activities = await service
        .getActivitiesStream('u1', const ['u2'])
        .firstWhere((items) => items.length == 3);

    expect(activities.map((activity) => activity.id), [
      'friend',
      'own',
      'global',
    ]);
  });

  test('likes stream from the current user updates feed state', () async {
    await seedActivity(
      'activity',
      actorUid: 'u1',
      visibility: 'friends',
      createdAt: DateTime(2026, 6, 4),
    );

    final emissions = service.getActivitiesStream('u1', const []);
    final first = await emissions.firstWhere((items) => items.isNotEmpty);
    expect(first.single.isLikedByCurrentUser, isFalse);

    await service.toggleLikeActivity('activity');
    final like = await firestore
        .collection('users')
        .doc('u1')
        .collection('activityLikes')
        .doc('activity')
        .get();
    expect(like.exists, isTrue);

    await service.toggleLikeActivity('activity');
    expect(
      (await firestore
              .collection('users')
              .doc('u1')
              .collection('activityLikes')
              .doc('activity')
              .get())
          .exists,
      isFalse,
    );
  });

  test('feed synthesizes friend milestones from public profile', () async {
    final fallbackTime = DateTime(2026, 6, 4, 9);
    await firestore.collection('publicProfiles').doc('u2').set({
      'uid': 'u2',
      'displayName': 'Friend',
      'avatarUrl': '',
      'currentLevel': 3,
      'currentClass': 'Novice',
      'streakDays': 7,
      'updatedAt': Timestamp.fromDate(DateTime(2026, 6, 4, 14)),
    });

    final activities = await service
        .getActivitiesStream(
          'u1',
          const ['u2'],
          fallbackActivityTimes: {'u2': fallbackTime},
        )
        .firstWhere((items) => items.length == 2);

    expect(activities.map((activity) => activity.id), [
      'level_u2_3',
      'streak_u2_7',
    ]);
    expect(activities.every((activity) => activity.isSynthetic), isTrue);
    expect(
      activities.every((activity) => activity.createdAt == fallbackTime),
      isTrue,
    );
  });

  test(
    'feed does not synthesize milestones when friend sharing is off',
    () async {
      await firestore.collection('publicProfiles').doc('u2').set({
        'uid': 'u2',
        'displayName': 'Friend',
        'avatarUrl': '',
        'currentLevel': 3,
        'currentClass': 'Novice',
        'streakDays': 7,
        'shareMilestones': false,
        'updatedAt': Timestamp.fromDate(DateTime(2026, 6, 4, 14)),
      });

      final activities = await service
          .getActivitiesStream('u1', const ['u2'])
          .firstWhere((items) => items.isEmpty);

      expect(activities, isEmpty);
    },
  );

  test('real activity wins over synthesized public profile fallback', () async {
    await seedActivity(
      'level_u2_3',
      actorUid: 'u2',
      visibility: 'friends',
      createdAt: DateTime(2026, 6, 4, 12),
    );
    await firestore.collection('publicProfiles').doc('u2').set({
      'uid': 'u2',
      'displayName': 'Friend',
      'avatarUrl': '',
      'currentLevel': 3,
      'currentClass': 'Novice',
      'streakDays': 0,
      'updatedAt': Timestamp.fromDate(DateTime(2026, 6, 4, 14)),
    });

    final activities = await service
        .getActivitiesStream('u1', const ['u2'])
        .firstWhere((items) => items.any((item) => item.id == 'level_u2_3'));
    final activity = activities.singleWhere((item) => item.id == 'level_u2_3');

    expect(activity.title, 'level_u2_3');
    expect(activity.isSynthetic, isFalse);
  });

  test('challenge totals are derived from contribution documents', () async {
    final challenge = firestore.collection('social_challenges').doc('steps');
    await challenge.set({
      'title': 'Steps',
      'description': '',
      'type': 'steps',
      'currentAmount': 999999,
      'targetAmount': 1000,
      'unit': 'Adım',
      'participants': ['u1'],
      'createdAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
      'endDate': Timestamp.fromDate(DateTime(2026, 6, 8)),
    });
    await challenge.collection('progressContributions').doc('u1_day').set({
      'creditedAmount': 300,
    });
    await challenge.collection('progressContributions').doc('u2_day').set({
      'creditedAmount': 250,
    });

    final challenges = await service.getChallengesStream().firstWhere(
      (items) => items.isNotEmpty,
    );

    expect(challenges.single.currentAmount, 550);
    expect(challenges.single.isCompleted, isFalse);
    expect(challenges.single.toJson().containsKey('currentAmount'), isFalse);
  });

  test('joining a challenge credits the current daily value once', () async {
    final today = AppDateUtils.todayKey();
    await firestore
        .collection('users')
        .doc('u1')
        .collection('dailyLogs')
        .doc(today)
        .set({'stepCount': 4200, 'waterGlasses': 2});
    await firestore.collection('social_challenges').doc('steps').set({
      'title': 'Steps',
      'description': '',
      'type': 'steps',
      'targetAmount': 10000,
      'unit': 'Adım',
      'participants': [],
      'createdAt': Timestamp.now(),
      'endDate': Timestamp.now(),
    });

    await service.toggleChallengeParticipation('steps');

    final contribution = await firestore
        .collection('social_challenges')
        .doc('steps')
        .collection('progressContributions')
        .doc('u1_$today')
        .get();
    expect(contribution.data()?['creditedAmount'], 4200);
  });
}
