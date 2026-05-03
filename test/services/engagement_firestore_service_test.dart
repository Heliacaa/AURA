import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/core/utils/date_utils.dart';
import 'package:aura/services/firestore_service.dart';
import 'package:aura/shared/models/daily_log_model.dart';
import 'package:aura/shared/models/user_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  const uid = 'uid1';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: fakeFirestore);
  });

  Future<void> seedUser({
    bool leaderboardOptIn = false,
    int weeklyXp = 0,
    String weeklyXpWeek = '',
  }) async {
    await fakeFirestore
        .collection('users')
        .doc(uid)
        .set(
          UserModel(
            uid: uid,
            displayName: 'Test User',
            email: 'test@test.com',
            createdAt: DateTime(2024, 1, 1),
            lastActiveDate: DateTime(2024, 1, 1),
            leaderboardOptIn: leaderboardOptIn,
            weeklyXp: weeklyXp,
            weeklyXpWeek: weeklyXpWeek,
          ).toFirestore(),
        );
  }

  Future<void> seedTodayLog(DailyLogModel log) async {
    await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('dailyLogs')
        .doc(AppDateUtils.todayKey())
        .set(log.toFirestore());
  }

  group('engagement rewards', () {
    test('claimDailyQuest awards once only', () async {
      await seedUser();
      await seedTodayLog(
        DailyLogModel.empty(AppDateUtils.todayKey()).copyWith(sleepHours: 7),
      );

      final firstClaim = await service.claimDailyQuest(
        uid: uid,
        questId: 'sleep_log',
        xpDelta: 25,
        statDeltas: {'vitality': 3},
        taskDescription: '+25 XP (Uyku görevi tamamlandı)',
      );
      final secondClaim = await service.claimDailyQuest(
        uid: uid,
        questId: 'sleep_log',
        xpDelta: 25,
        statDeltas: {'vitality': 3},
        taskDescription: '+25 XP (Uyku görevi tamamlandı)',
      );

      expect(firstClaim, isTrue);
      expect(secondClaim, isFalse);

      final userDoc = await fakeFirestore.collection('users').doc(uid).get();
      final userData = userDoc.data()!;
      expect(userData['xp'], 25);
      expect(userData['weeklyXp'], 25);
      expect(userData['weeklyXpWeek'], AppDateUtils.weekKey());
      expect(userData['stats']['vitality'], 3);

      final logDoc = await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('dailyLogs')
          .doc(AppDateUtils.todayKey())
          .get();
      final logData = logDoc.data()!;
      expect(logData['claimedQuestIds'], ['sleep_log']);
      expect(logData['xpEarned'], 25);
      expect(logData['completedTasks'], ['+25 XP (Uyku görevi tamamlandı)']);
    });

    test('updateUserXP increments current weekly XP', () async {
      await seedUser(leaderboardOptIn: true);
      await seedTodayLog(DailyLogModel.empty(AppDateUtils.todayKey()));

      await service.updateUserXP(
        uid: uid,
        xpDelta: 40,
        taskDescription: '+40 XP',
      );

      final userDoc = await fakeFirestore.collection('users').doc(uid).get();
      final data = userDoc.data()!;
      expect(data['xp'], 40);
      expect(data['weeklyXp'], 40);
      expect(data['weeklyXpWeek'], AppDateUtils.weekKey());
    });

    test('stale weekly XP resets before adding new XP', () async {
      await seedUser(
        leaderboardOptIn: true,
        weeklyXp: 300,
        weeklyXpWeek: '2020-W01',
      );

      await service.updateUserXP(uid: uid, xpDelta: 10);

      final userDoc = await fakeFirestore.collection('users').doc(uid).get();
      final data = userDoc.data()!;
      expect(data['weeklyXp'], 10);
      expect(data['weeklyXpWeek'], AppDateUtils.weekKey());
    });

    test('opt-out users do not appear in the weekly leaderboard', () async {
      await seedUser(leaderboardOptIn: false);

      await service.updateUserXP(uid: uid, xpDelta: 10);

      final entries = await service.getWeeklyLeaderboard();
      expect(entries, isEmpty);
    });

    test('opt-in users appear with public leaderboard fields only', () async {
      await seedUser(leaderboardOptIn: true);

      await service.updateUserXP(uid: uid, xpDelta: 10);

      final entries = await service.getWeeklyLeaderboard();
      expect(entries.length, 1);
      expect(entries.first['uid'], uid);
      expect(entries.first['displayName'], 'Test User');
      expect(entries.first['weeklyXp'], 10);
      expect(entries.first['weekKey'], AppDateUtils.weekKey());
      expect(entries.first['updatedAt'], isA<Timestamp>());
      expect(entries.first.containsKey('email'), isFalse);
      expect(entries.first.containsKey('dailyGoals'), isFalse);
      expect(entries.first.containsKey('streakDays'), isFalse);
    });
  });
}
