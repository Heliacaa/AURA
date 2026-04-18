import 'package:flutter_test/flutter_test.dart';
import 'package:aura/shared/models/friendship_model.dart';

void main() {
  group('FriendshipModel', () {
    test('isPending and isAccepted', () {
      final pending = FriendshipModel(
        friendUid: 'uid1',
        friendName: 'Alice',
        friendEmail: 'alice@test.com',
        status: 'pending',
        createdAt: DateTime(2024, 6, 15),
      );

      expect(pending.isPending, isTrue);
      expect(pending.isAccepted, isFalse);

      final accepted = pending.copyWith(status: 'accepted');
      expect(accepted.isPending, isFalse);
      expect(accepted.isAccepted, isTrue);
    });

    test('copyWith preserves other fields', () {
      final friend = FriendshipModel(
        friendUid: 'uid2',
        friendName: 'Bob',
        friendEmail: 'bob@test.com',
        status: 'pending',
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = friend.copyWith(status: 'accepted');
      expect(updated.friendUid, 'uid2');
      expect(updated.friendName, 'Bob');
      expect(updated.friendEmail, 'bob@test.com');
      expect(updated.status, 'accepted');
    });

    test('toFirestore serializes', () {
      final friend = FriendshipModel(
        friendUid: 'uid3',
        friendName: 'Charlie',
        friendEmail: 'charlie@test.com',
        status: 'accepted',
        createdAt: DateTime(2024, 3, 20),
      );

      final map = friend.toFirestore();
      expect(map['friendName'], 'Charlie');
      expect(map['friendEmail'], 'charlie@test.com');
      expect(map['status'], 'accepted');
    });
  });
}
