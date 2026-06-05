import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/social/models/activity.dart';
import 'package:aura/features/social/providers/social_providers.dart';

void main() {
  test('parses typed social activity fields', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('social_activities').doc('streak_u1_10').set({
      'type': 'streak_milestone',
      'actorUid': 'u1',
      'actorDisplayName': 'Ahmet',
      'actorAvatarUrl': '',
      'title': '10 Günlük Seri!',
      'description': 'Ahmet, 10 günlük seriye ulaştı.',
      'metadata': {'days': 10},
      'visibility': 'friends',
      'createdAt': Timestamp.fromDate(DateTime(2026, 6, 4)),
      'isSpecialAchievement': true,
    });

    final doc = await firestore
        .collection('social_activities')
        .doc('streak_u1_10')
        .get();
    final activity = ActivityFeedItem.fromFirestore(
      doc,
      isLikedByCurrentUser: true,
    );

    expect(activity.type, ActivityType.streakMilestone);
    expect(activity.actorUid, 'u1');
    expect(activity.metadata['days'], 10);
    expect(activity.isLikedByCurrentUser, isTrue);
  });

  test('copyWith updates current-user like state', () {
    final activity = ActivityFeedItem(
      id: 'global',
      type: ActivityType.communityChallengeCompleted,
      actorUid: '',
      actorDisplayName: 'AURA Topluluğu',
      actorAvatarUrl: '',
      title: 'Hedef tamamlandı',
      description: '',
      metadata: const {},
      visibility: 'global',
      createdAt: DateTime(2026, 6, 4),
      isSpecialAchievement: true,
    );

    expect(
      activity.copyWith(isLikedByCurrentUser: true).isLikedByCurrentUser,
      isTrue,
    );
  });

  test('unread count excludes own and previously read activities', () {
    ActivityFeedItem activity(String id, String actorUid, DateTime createdAt) {
      return ActivityFeedItem(
        id: id,
        type: ActivityType.levelUp,
        actorUid: actorUid,
        actorDisplayName: actorUid,
        actorAvatarUrl: '',
        title: 'Seviye',
        description: '',
        metadata: const {},
        visibility: 'friends',
        createdAt: createdAt,
        isSpecialAchievement: true,
      );
    }

    final count = countUnreadActivities(
      activities: [
        activity('new-friend', 'u2', DateTime(2026, 6, 4, 12)),
        activity('old-friend', 'u2', DateTime(2026, 6, 4, 9)),
        activity('own', 'u1', DateTime(2026, 6, 4, 13)),
      ],
      currentUid: 'u1',
      lastReadAt: DateTime(2026, 6, 4, 10),
    );

    expect(count, 1);
  });
}
