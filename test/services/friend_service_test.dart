import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura/core/utils/date_utils.dart';
import 'package:aura/services/friend_service.dart';

void main() {
  group('FriendService', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late FriendService service;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'uid1',
          email: 'alice@test.com',
          displayName: 'Alice',
        ),
        signedIn: true,
      );
      service = FriendService(firestore: firestore, auth: auth);

      await firestore.collection('publicProfiles').doc('uid1').set({
        'uid': 'uid1',
        'displayName': 'Alice',
        'email': 'alice@test.com',
        'avatarUrl': '',
        'currentLevel': 1,
        'currentClass': 'Novice',
        'xp': 0,
        'streakDays': 0,
        'weeklyXp': 0,
        'weeklyXpWeek': '',
      });
      await firestore.collection('publicProfiles').doc('uid2').set({
        'uid': 'uid2',
        'displayName': 'Bob',
        'email': 'bob@test.com',
        'avatarUrl': '',
        'currentLevel': 2,
        'currentClass': 'Novice',
        'xp': 130,
        'streakDays': 1,
        'weeklyXp': 630,
        'weeklyXpWeek': '',
      });
    });

    test('sendFriendRequest creates a pending friendship', () async {
      await service.sendFriendRequest('uid2');

      final doc = await firestore
          .collection('friendships')
          .doc('uid1_uid2')
          .get();
      final data = doc.data();

      expect(doc.exists, isTrue);
      expect(data?['participantUids'], ['uid1', 'uid2']);
      expect(data?['requesterUid'], 'uid1');
      expect(data?['recipientUid'], 'uid2');
      expect(data?['status'], 'pending');
      expect(data?['requester']['displayName'], 'Alice');
      expect(data?['recipient']['displayName'], 'Bob');
    });

    test(
      'sendFriendRequest can use leaderboard-only recipient profiles',
      () async {
        final weekKey = AppDateUtils.weekKey();
        await firestore.collection('publicProfiles').doc('uid2').delete();
        await firestore
            .collection('leaderboards')
            .doc(weekKey)
            .collection('entries')
            .doc('uid2')
            .set({
              'uid': 'uid2',
              'displayName': 'Ediz Arkin',
              'currentLevel': 2,
              'currentClass': 'Novice',
              'weeklyXp': 630,
              'weekKey': weekKey,
              'updatedAt': Timestamp.fromDate(DateTime(2026, 5, 15)),
            });

        await service.sendFriendRequest('uid2');

        final doc = await firestore
            .collection('friendships')
            .doc('uid1_uid2')
            .get();
        final data = doc.data();

        expect(doc.exists, isTrue);
        expect(data?['recipient']['displayName'], 'Ediz Arkin');
        expect(data?['recipient']['email'], '');
      },
    );

    test('sendFriendRequest rejects self before writing', () async {
      expect(
        () => service.sendFriendRequest('uid1'),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'failed-precondition',
          ),
        ),
      );
      final docs = await firestore.collection('friendships').get();
      expect(docs.docs, isEmpty);
    });

    test('sendFriendRequest rejects duplicate requests', () async {
      await service.sendFriendRequest('uid2');

      expect(
        () => service.sendFriendRequest('uid2'),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'already-exists',
          ),
        ),
      );
    });

    test(
      'sendFriendRequest detects an existing directional friendship',
      () async {
        await firestore.collection('publicProfiles').doc('uid0').set({
          'uid': 'uid0',
          'displayName': 'Zero',
          'email': 'zero@test.com',
          'avatarUrl': '',
          'currentLevel': 1,
          'currentClass': 'Novice',
          'xp': 0,
          'streakDays': 0,
          'weeklyXp': 0,
          'weeklyXpWeek': '',
        });
        await firestore.collection('friendships').doc('uid1_uid0').set({
          'participantUids': ['uid1', 'uid0'],
          'requesterUid': 'uid1',
          'recipientUid': 'uid0',
          'status': 'accepted',
        });

        expect(
          () => service.sendFriendRequest('uid0'),
          throwsA(
            isA<FirebaseException>().having(
              (error) => error.code,
              'code',
              'already-exists',
            ),
          ),
        );
      },
    );

    test(
      'removeFriend deletes directional friendship and is idempotent',
      () async {
        await firestore.collection('friendships').doc('uid1_uid0').set({
          'participantUids': ['uid1', 'uid0'],
          'requesterUid': 'uid1',
          'recipientUid': 'uid0',
          'status': 'accepted',
        });

        await service.removeFriend('uid0');

        expect(
          (await firestore.collection('friendships').doc('uid1_uid0').get())
              .exists,
          isFalse,
        );

        await service.removeFriend('uid0');
      },
    );
  });
}
