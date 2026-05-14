import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aura/shared/models/user_model.dart';
import 'package:aura/shared/models/meal_model.dart';
import 'package:aura/shared/models/chat_message_model.dart';
import 'package:aura/shared/models/friendship_model.dart';
import 'package:aura/services/firestore_service.dart';
import 'package:aura/core/utils/date_utils.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('User operations', () {
    test('create and read user document', () async {
      final userRef = fakeFirestore.collection('users').doc('uid1');
      final user = UserModel(
        uid: 'uid1',
        displayName: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2024, 1, 1),
        lastActiveDate: DateTime(2024, 6, 1),
        xp: 1000,
        currentLevel: 3,
      );

      await userRef.set(user.toFirestore());

      final doc = await userRef.get();
      expect(doc.exists, isTrue);

      final restored = UserModel.fromFirestore(doc);
      expect(restored.uid, 'uid1');
      expect(restored.displayName, 'Test User');
      expect(restored.email, 'test@test.com');
      expect(restored.xp, 1000);
      expect(restored.currentLevel, 3);
    });

    test('update user fields', () async {
      final userRef = fakeFirestore.collection('users').doc('uid1');
      await userRef.set({
        'displayName': 'Old Name',
        'email': 'test@test.com',
        'xp': 0,
        'currentLevel': 1,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'lastActiveDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      await userRef.update({'displayName': 'New Name', 'xp': 500});

      final doc = await userRef.get();
      final data = doc.data()!;
      expect(data['displayName'], 'New Name');
      expect(data['xp'], 500);
    });

    test(
      'update profile settings writes private and public profile data',
      () async {
        final service = FirestoreService(firestore: fakeFirestore);
        final userRef = fakeFirestore.collection('users').doc('uid1');
        await userRef.set({
          'displayName': 'Old Name',
          'email': 'test@test.com',
          'emailLower': 'test@test.com',
          'xp': 200,
          'currentLevel': 2,
          'currentClass': 'Novice',
          'weeklyXp': 50,
          'weeklyXpWeek': '2026-W18',
          'leaderboardOptIn': false,
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'lastActiveDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });

        await service.updateProfileSettings(
          uid: 'uid1',
          displayName: 'New Name',
          age: 31,
          heightCm: 181,
          weightKg: 82.5,
          dailyGoals: const DailyGoals(
            steps: 9000,
            calories: 2100,
            waterGlasses: 9,
          ),
          socialEnergyLevel: 'Yüksek',
          leaderboardOptIn: true,
        );

        final privateData = (await userRef.get()).data()!;
        expect(privateData['displayName'], 'New Name');
        expect(privateData['age'], 31);
        expect(privateData['heightCm'], 181);
        expect(privateData['weightKg'], 82.5);
        expect(privateData['dailyGoals']['calories'], 2100);
        expect(privateData['socialEnergyLevel'], 'Yüksek');
        expect(privateData['leaderboardOptIn'], isTrue);

        final publicData =
            (await fakeFirestore.collection('publicProfiles').doc('uid1').get())
                .data()!;
        expect(publicData['displayName'], 'New Name');
        expect(publicData.containsKey('heightCm'), isFalse);
        expect(publicData.containsKey('weightKg'), isFalse);

        final leaderboardDoc = await fakeFirestore
            .collection('leaderboards')
            .doc(AppDateUtils.weekKey())
            .collection('entries')
            .doc('uid1')
            .get();
        expect(leaderboardDoc.exists, isTrue);
        expect(leaderboardDoc.data()?['displayName'], 'New Name');
      },
    );

    test('user stream emits updates', () async {
      final userRef = fakeFirestore.collection('users').doc('uid1');
      await userRef.set({
        'displayName': 'Initial',
        'email': 'test@test.com',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'lastActiveDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      final stream = userRef.snapshots().map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      });

      expectLater(
        stream,
        emitsInOrder([
          predicate<UserModel?>((u) => u?.displayName == 'Initial'),
          predicate<UserModel?>((u) => u?.displayName == 'Updated'),
        ]),
      );

      await userRef.update({'displayName': 'Updated'});
    });

    test('find user by email', () async {
      await fakeFirestore.collection('users').doc('uid1').set({
        'displayName': 'Alice',
        'email': 'alice@test.com',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'lastActiveDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      final snap = await fakeFirestore
          .collection('users')
          .where('email', isEqualTo: 'alice@test.com')
          .limit(1)
          .get();

      expect(snap.docs.length, 1);
      final user = UserModel.fromFirestore(snap.docs.first);
      expect(user.displayName, 'Alice');
    });

    test('find user by email returns empty for non-existent', () async {
      final snap = await fakeFirestore
          .collection('users')
          .where('email', isEqualTo: 'nobody@test.com')
          .limit(1)
          .get();
      expect(snap.docs, isEmpty);
    });
  });

  group('Meals operations', () {
    test('save and retrieve meal', () async {
      final mealsRef = fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('meals');
      final meal = MealModel(
        timestamp: DateTime(2024, 6, 15, 12, 30),
        detectedFood: 'Pizza',
        calories: 350,
        protein: 15.0,
        carbs: 40.0,
        fat: 12.0,
        aiAdvice: 'Good choice!',
      );

      await mealsRef.add(meal.toFirestore());

      final snap = await mealsRef.get();
      expect(snap.docs.length, 1);

      final restored = MealModel.fromFirestore(snap.docs.first);
      expect(restored.detectedFood, 'Pizza');
      expect(restored.calories, 350);
      expect(restored.protein, 15.0);
    });

    test('multiple meals accumulate', () async {
      final mealsRef = fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('meals');

      await mealsRef.add(
        MealModel(
          timestamp: DateTime(2024, 6, 15, 8, 0),
          detectedFood: 'Oatmeal',
          calories: 200,
          protein: 8.0,
          carbs: 35.0,
          fat: 3.0,
        ).toFirestore(),
      );

      await mealsRef.add(
        MealModel(
          timestamp: DateTime(2024, 6, 15, 13, 0),
          detectedFood: 'Salad',
          calories: 150,
          protein: 5.0,
          carbs: 20.0,
          fat: 6.0,
        ).toFirestore(),
      );

      final snap = await mealsRef.get();
      expect(snap.docs.length, 2);

      int totalCalories = 0;
      for (final doc in snap.docs) {
        final meal = MealModel.fromFirestore(doc);
        totalCalories += meal.calories;
      }
      expect(totalCalories, 350);
    });
  });

  group('Chat operations', () {
    test('save and retrieve chat messages', () async {
      final chatRef = fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('chatHistory');

      await chatRef.add(ChatMessageModel.user('Hello').toFirestore());
      await chatRef.add(ChatMessageModel.assistant('Hi there!').toFirestore());

      final snap = await chatRef.get();
      expect(snap.docs.length, 2);

      final messages = snap.docs
          .map((d) => ChatMessageModel.fromFirestore(d))
          .toList();
      expect(messages.any((m) => m.role == 'user'), isTrue);
      expect(messages.any((m) => m.role == 'assistant'), isTrue);
    });
  });

  group('Friends operations', () {
    test('send and accept friend request', () async {
      final friendships = fakeFirestore.collection('friendships');
      final createdAt = DateTime(2024, 6, 15);

      // Send friend request
      await friendships
          .doc('uid1_uid2')
          .set(
            FriendshipModel(
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
            ).toFirestore(),
          );

      // Verify pending
      var doc = await friendships.doc('uid1_uid2').get();
      expect(doc.data()?['status'], 'pending');

      // Accept
      await friendships.doc('uid1_uid2').update({'status': 'accepted'});

      doc = await friendships.doc('uid1_uid2').get();
      expect(doc.data()?['status'], 'accepted');
    });

    test('remove friend deletes relationship', () async {
      final friendships = fakeFirestore.collection('friendships');

      await friendships.doc('uid1_uid2').set({
        'participantUids': ['uid1', 'uid2'],
        'requesterUid': 'uid1',
        'recipientUid': 'uid2',
        'status': 'accepted',
      });

      // Remove
      await friendships.doc('uid1_uid2').delete();

      final snap = await friendships.get();
      expect(snap.docs, isEmpty);
    });

    test('query accepted and pending relationships for participant', () async {
      final friendships = fakeFirestore.collection('friendships');

      await friendships.doc('uid1_uid2').set({
        'participantUids': ['uid1', 'uid2'],
        'requesterUid': 'uid1',
        'recipientUid': 'uid2',
        'status': 'accepted',
        'createdAt': Timestamp.fromDate(DateTime(2024, 6, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 6, 1)),
        'requester': {'uid': 'uid1', 'displayName': 'Alice'},
        'recipient': {'uid': 'uid2', 'displayName': 'Bob'},
      });
      await friendships.doc('uid1_uid3').set({
        'participantUids': ['uid1', 'uid3'],
        'requesterUid': 'uid3',
        'recipientUid': 'uid1',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime(2024, 6, 2)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 6, 2)),
        'requester': {'uid': 'uid3', 'displayName': 'Charlie'},
        'recipient': {'uid': 'uid1', 'displayName': 'Alice'},
      });

      final all = await friendships
          .where('participantUids', arrayContains: 'uid1')
          .get();
      final models = all.docs.map(FriendshipModel.fromFirestore).toList();
      final accepted = models.where((item) => item.isAccepted).toList();
      final incoming = models
          .where((item) => item.isIncomingFor('uid1'))
          .toList();

      expect(accepted.length, 1);
      expect(accepted.first.otherUser('uid1').displayName, 'Bob');
      expect(incoming.length, 1);
      expect(incoming.first.otherUser('uid1').displayName, 'Charlie');
    });
  });

  group('Daily Log operations', () {
    test('create and read daily log', () async {
      final logsRef = fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('dailyLogs');

      await logsRef.doc('2024-06-15').set({
        'date': Timestamp.fromDate(DateTime(2024, 6, 15)),
        'stepCount': 8000,
        'caloriesConsumed': 1500,
        'waterGlasses': 6,
        'mood': '😊',
        'completedTasks': ['walk'],
        'dailyScore': 75,
        'xpEarned': 100,
        'mealsLogged': 2,
        'sleepHours': 7.5,
        'sleepQuality': 'good',
        'caloriesBurned': 200,
      });

      final doc = await logsRef.doc('2024-06-15').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['stepCount'], 8000);
      expect(doc.data()?['sleepHours'], 7.5);
      expect(doc.data()?['sleepQuality'], 'good');
    });
  });

  group('Memories operations', () {
    test('save and query memories', () async {
      final memoriesRef = fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('memories');

      await memoriesRef.add({
        'content': 'Has exam on Monday',
        'category': 'exam',
        'extractedAt': Timestamp.fromDate(DateTime(2024, 6, 15)),
      });
      await memoriesRef.add({
        'content': 'Wants to lose weight',
        'category': 'health',
        'extractedAt': Timestamp.fromDate(DateTime(2024, 6, 14)),
      });

      final snap = await memoriesRef.get();
      expect(snap.docs.length, 2);
    });
  });
}
