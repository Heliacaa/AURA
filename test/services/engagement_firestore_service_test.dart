import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/core/utils/date_utils.dart';
import 'package:aura/features/home/models/daily_quest.dart';
import 'package:aura/services/firestore_service.dart';
import 'package:aura/shared/models/achievement_catalog.dart';
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
    int xp = 0,
    int currentLevel = 1,
    int streakDays = 0,
    DateTime? lastActiveDate,
    bool shareMilestones = true,
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
            lastActiveDate: lastActiveDate ?? DateTime(2024, 1, 1),
            xp: xp,
            currentLevel: currentLevel,
            streakDays: streakDays,
            leaderboardOptIn: leaderboardOptIn,
            weeklyXp: weeklyXp,
            weeklyXpWeek: weeklyXpWeek,
            shareMilestones: shareMilestones,
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

      final achievementDoc = await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .doc(AchievementIds.firstQuest)
          .get();
      expect(achievementDoc.exists, isTrue);
    });

    test('claimDailyQuest unlocks daily combo achievement', () async {
      await seedUser();
      await seedTodayLog(
        DailyLogModel.empty(AppDateUtils.todayKey()).copyWith(
          claimedQuestIds: DailyQuestCatalog.forDate(
            DateTime.now(),
          ).map((quest) => quest.id).toList(),
        ),
      );

      final claimed = await service.claimDailyQuest(
        uid: uid,
        questId: DailyQuestIds.combo,
        xpDelta: 40,
        statDeltas: const {'charisma': 2, 'vitality': 2},
        taskDescription: '+40 XP (Günlük kombo tamamlandı)',
      );

      expect(claimed, isTrue);
      final comboAchievement = await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .doc(AchievementIds.dailyCombo)
          .get();
      expect(comboAchievement.exists, isTrue);
    });

    test(
      'claimWeeklyQuest awards once and unlocks weekly achievements',
      () async {
        await seedUser(leaderboardOptIn: true);

        final firstClaim = await service.claimWeeklyQuest(
          uid: uid,
          questId: WeeklyQuestIds.steps,
          xpDelta: 90,
          statDeltas: const {'strength': 6},
          taskDescription: '+90 XP (Haftalık adım görevi tamamlandı)',
        );
        final secondClaim = await service.claimWeeklyQuest(
          uid: uid,
          questId: WeeklyQuestIds.steps,
          xpDelta: 90,
          statDeltas: const {'strength': 6},
          taskDescription: '+90 XP (Haftalık adım görevi tamamlandı)',
        );

        expect(firstClaim, isTrue);
        expect(secondClaim, isFalse);

        final userDoc = await fakeFirestore.collection('users').doc(uid).get();
        final userData = userDoc.data()!;
        expect(userData['xp'], 90);
        expect(userData['weeklyXp'], 90);
        expect(userData['stats']['strength'], 6);

        final weeklyLog = await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('weeklyQuestLogs')
            .doc(AppDateUtils.weekKey())
            .get();
        final logData = weeklyLog.data()!;
        expect(logData['claimedQuestIds'], [WeeklyQuestIds.steps]);
        expect(logData['xpEarned'], 90);

        final achievements = await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('achievements')
            .get();
        final achievementIds = achievements.docs.map((doc) => doc.id).toSet();
        expect(achievementIds, contains(AchievementIds.firstQuest));
        expect(achievementIds, contains(AchievementIds.firstWeeklyQuest));
        expect(achievementIds, contains(AchievementIds.weeklySteps));

        final entries = await service.getWeeklyLeaderboard();
        expect(entries.single['weeklyXp'], 90);
      },
    );

    test('unlockAchievementIfMissing is idempotent', () async {
      await seedUser();

      final first = await service.unlockAchievementIfMissing(
        uid,
        AchievementCatalog.firstQuest,
      );
      final second = await service.unlockAchievementIfMissing(
        uid,
        AchievementCatalog.firstQuest,
      );

      final achievements = await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .get();

      expect(first, isTrue);
      expect(second, isFalse);
      expect(achievements.docs.length, 1);

      final activity = await fakeFirestore
          .collection('social_activities')
          .doc('achievement_uid1_${AchievementCatalog.firstQuest.id}')
          .get();
      expect(activity.exists, isTrue);
      expect(
        activity.data()?['metadata']['achievementId'],
        AchievementCatalog.firstQuest.id,
      );
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

    test('level-up creates one deterministic social activity', () async {
      await seedUser(xp: 490);
      await seedTodayLog(DailyLogModel.empty(AppDateUtils.todayKey()));

      expect(await service.updateUserXP(uid: uid, xpDelta: 20), isTrue);

      final activity = await fakeFirestore
          .collection('social_activities')
          .doc('level_uid1_2')
          .get();
      expect(activity.exists, isTrue);
      expect(activity.data()?['actorUid'], uid);
      expect(activity.data()?['metadata']['level'], 2);
      expect(activity.data()?.containsKey('audienceUids'), isFalse);
    });

    test('shareMilestones false suppresses social activities', () async {
      await seedUser(xp: 490, shareMilestones: false);
      await seedTodayLog(DailyLogModel.empty(AppDateUtils.todayKey()));

      await service.updateUserXP(uid: uid, xpDelta: 20);

      expect(
        (await fakeFirestore.collection('social_activities').get()).docs,
        isEmpty,
      );
    });

    test('streak milestone creates a deterministic social activity', () async {
      await seedUser(
        streakDays: 2,
        lastActiveDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      await service.updateStreak(uid);

      final activity = await fakeFirestore
          .collection('social_activities')
          .doc('streak_uid1_3')
          .get();
      expect(activity.exists, isTrue);
      expect(activity.data()?['metadata']['days'], 3);
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

    test('streak milestone helper uses fixed and hundred-day milestones', () {
      expect(FirestoreService.isStreakMilestone(3), isTrue);
      expect(FirestoreService.isStreakMilestone(100), isTrue);
      expect(FirestoreService.isStreakMilestone(200), isTrue);
      expect(FirestoreService.isStreakMilestone(12), isFalse);
    });
  });
}
