import 'package:flutter_test/flutter_test.dart';
import 'package:aura/shared/models/friendship_model.dart';

void main() {
  group('FriendshipModel', () {
    final createdAt = DateTime(2024, 6, 15);

    FriendshipModel pending() {
      return FriendshipModel(
        id: 'uid1_uid2',
        participantUids: const ['uid1', 'uid2'],
        requesterUid: 'uid1',
        recipientUid: 'uid2',
        status: 'pending',
        createdAt: createdAt,
        updatedAt: createdAt,
        requester: const FriendSnapshot(
          uid: 'uid1',
          displayName: 'Alice',
          email: 'alice@test.com',
        ),
        recipient: const FriendSnapshot(
          uid: 'uid2',
          displayName: 'Bob',
          email: 'bob@test.com',
        ),
      );
    }

    test('isPending and isAccepted', () {
      final request = pending();
      expect(request.isPending, isTrue);
      expect(request.isAccepted, isFalse);

      final accepted = request.copyWith(status: 'accepted');
      expect(accepted.isPending, isFalse);
      expect(accepted.isAccepted, isTrue);
    });

    test('detects incoming and outgoing direction', () {
      final request = pending();
      expect(request.isOutgoingFor('uid1'), isTrue);
      expect(request.isIncomingFor('uid2'), isTrue);
      expect(request.isIncomingFor('uid1'), isFalse);
      expect(request.isOutgoingFor('uid2'), isFalse);
    });

    test('returns the other participant snapshot', () {
      final request = pending();
      expect(request.otherUid('uid1'), 'uid2');
      expect(request.otherUser('uid1').displayName, 'Bob');
      expect(request.otherUid('uid2'), 'uid1');
      expect(request.otherUser('uid2').displayName, 'Alice');
    });

    test('toFirestore serializes directed relationship', () {
      final map = pending().toFirestore();
      expect(map['participantUids'], ['uid1', 'uid2']);
      expect(map['requesterUid'], 'uid1');
      expect(map['recipientUid'], 'uid2');
      expect(map['status'], 'pending');
      expect(map['requester']['displayName'], 'Alice');
      expect(map['recipient']['email'], 'bob@test.com');
    });
  });
}
