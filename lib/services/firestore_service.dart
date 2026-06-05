import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../shared/models/user_model.dart';
import '../shared/models/daily_log_model.dart';
import '../shared/models/meal_model.dart';
import '../shared/models/chat_message_model.dart';
import '../shared/models/achievement_model.dart';
import '../shared/models/achievement_catalog.dart';
import '../shared/models/friendship_model.dart';
import '../shared/models/weekly_quest_log_model.dart';
import '../core/utils/date_utils.dart';
import '../features/home/models/daily_quest.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  FirestoreService._() : _db = FirebaseFirestore.instance;

  static final instance = FirestoreService._();

  final FirebaseFirestore _db;

  // ─── References ───────────────────────────────────────────

  DocumentReference _userDoc(String uid) => _db.collection('users').doc(uid);

  CollectionReference _dailyLogs(String uid) =>
      _userDoc(uid).collection('dailyLogs');

  CollectionReference _meals(String uid) => _userDoc(uid).collection('meals');

  CollectionReference _chatHistory(String uid) =>
      _userDoc(uid).collection('chatHistory');

  CollectionReference _achievements(String uid) =>
      _userDoc(uid).collection('achievements');

  CollectionReference _weeklyQuestLogs(String uid) =>
      _userDoc(uid).collection('weeklyQuestLogs');

  CollectionReference _friendships() => _db.collection('friendships');

  DocumentReference _publicProfile(String uid) =>
      _db.collection('publicProfiles').doc(uid);

  DocumentReference _friendProfile(String uid) =>
      _db.collection('friendProfiles').doc(uid);

  DocumentReference _userSearchDoc(String email) =>
      _db.collection('userSearch').doc(email.toLowerCase());

  CollectionReference _leaderboardEntries(String weekKey) =>
      _db.collection('leaderboards').doc(weekKey).collection('entries');

  DocumentReference _leaderboardEntry(String weekKey, String uid) =>
      _leaderboardEntries(weekKey).doc(uid);

  DocumentReference _socialActivity(String activityId) =>
      _db.collection('social_activities').doc(activityId);

  // ─── User ─────────────────────────────────────────────────

  /// Create initial user document with defaults
  Future<void> createUserDoc({
    required String uid,
    required String displayName,
    required String email,
    String avatarUrl = '',
  }) async {
    final user = UserModel(
      uid: uid,
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
      createdAt: DateTime.now(),
      lastActiveDate: DateTime.now(),
    );
    await _userDoc(uid).set(user.toFirestore());
    await _syncProfileProjections(user);
  }

  /// Ensure user document exists — create if missing
  Future<void> ensureUserDoc({
    required String uid,
    required String displayName,
    required String email,
    String avatarUrl = '',
  }) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) {
      await createUserDoc(
        uid: uid,
        displayName: displayName,
        email: email,
        avatarUrl: avatarUrl,
      );
      return;
    }

    final data = doc.data() as Map<String, dynamic>? ?? {};
    final updates = <String, dynamic>{};
    if ((data['displayName'] as String? ?? '').isEmpty &&
        displayName.isNotEmpty) {
      updates['displayName'] = displayName;
    }
    if ((data['email'] as String? ?? '').isEmpty && email.isNotEmpty) {
      updates['email'] = email;
    }
    if ((data['avatarUrl'] as String? ?? '').isEmpty && avatarUrl.isNotEmpty) {
      updates['avatarUrl'] = avatarUrl;
    }
    if ((data['emailLower'] as String? ?? '').isEmpty && email.isNotEmpty) {
      updates['emailLower'] = email.toLowerCase();
    }
    if (!data.containsKey('avatarUrl')) {
      updates['avatarUrl'] = avatarUrl;
    }
    if (!data.containsKey('currentLevel')) {
      updates['currentLevel'] = 1;
    }
    final currentLevel = (data['currentLevel'] as num?)?.toInt() ?? 1;
    if (!data.containsKey('currentClass')) {
      updates['currentClass'] = UserModel.classForLevel(currentLevel);
    }
    if (!data.containsKey('xp')) {
      updates['xp'] = 0;
    }
    if (!data.containsKey('xpToNextLevel')) {
      updates['xpToNextLevel'] = UserModel.xpForLevel(currentLevel);
    }
    if (!data.containsKey('shareMilestones')) {
      updates['shareMilestones'] = true;
    }
    final storedNotificationPreferences = data['notificationPreferences'];
    if (storedNotificationPreferences is! Map ||
        !storedNotificationPreferences.containsKey('waterReminders') ||
        !storedNotificationPreferences.containsKey('dailyGoalReminder')) {
      updates['notificationPreferences'] = storedNotificationPreferences is Map
          ? NotificationPreferences.fromMap(
              Map<String, dynamic>.from(storedNotificationPreferences),
            ).toMap()
          : const NotificationPreferences().toMap();
    }
    if (updates.isNotEmpty) {
      await _userDoc(uid).update(updates);
    }
    final refreshed = await _userDoc(uid).get();
    if (refreshed.exists) {
      await _syncProfileProjections(UserModel.fromFirestore(refreshed));
    }
  }

  /// Stream user data
  Stream<UserModel?> userStream(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Update user fields
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _userDoc(uid).update(data);
  }

  Future<void> markSocialFeedRead(String uid) async {
    await _userDoc(
      uid,
    ).update({'lastSocialFeedReadAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateProfileSettings({
    required String uid,
    required String displayName,
    required int? age,
    required int? heightCm,
    required double? weightKg,
    required DailyGoals dailyGoals,
    required String socialEnergyLevel,
    required bool leaderboardOptIn,
    required bool shareMilestones,
    required NotificationPreferences notificationPreferences,
  }) async {
    await _userDoc(uid).update({
      'displayName': displayName,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'dailyGoals': dailyGoals.toMap(),
      'socialEnergyLevel': socialEnergyLevel,
      'shareMilestones': shareMilestones,
      'notificationPreferences': notificationPreferences.toMap(),
    });

    final doc = await _userDoc(uid).get();
    if (doc.exists) {
      await _syncProfileProjections(UserModel.fromFirestore(doc));
    }

    await setLeaderboardOptIn(uid, leaderboardOptIn);
  }

  /// Atomic XP and stat update using transaction
  Future<bool> updateUserXP({
    required String uid,
    required int xpDelta,
    Map<String, int> statDeltas = const {},
    String? taskDescription,
  }) async {
    bool leveledUp = false;
    final currentWeek = AppDateUtils.weekKey();

    await _db.runTransaction((transaction) async {
      final userRef = _userDoc(uid);
      final today = AppDateUtils.todayKey();
      final logRef = _dailyLogs(uid).doc(today);
      final leaderboardRef = _leaderboardEntry(currentWeek, uid);

      final userDoc = await transaction.get(userRef);
      final logDoc = await transaction.get(logRef);
      if (!userDoc.exists) return;

      final data = userDoc.data() as Map<String, dynamic>;
      final reward = _calculateRewardUpdate(
        userData: data,
        xpDelta: xpDelta,
        statDeltas: statDeltas,
        currentWeek: currentWeek,
      );
      leveledUp = reward.leveledUp;
      _writeRewardUpdates(
        transaction: transaction,
        userRef: userRef,
        leaderboardRef: leaderboardRef,
        uid: uid,
        userData: data,
        reward: reward,
        currentWeek: currentWeek,
      );

      // Also update today's log xpEarned
      if (logDoc.exists) {
        final logData = logDoc.data() as Map<String, dynamic>? ?? {};
        final earned = (logData['xpEarned'] as num?)?.toInt() ?? 0;
        final tasks = List<String>.from(logData['completedTasks'] ?? []);
        if (taskDescription != null) tasks.add(taskDescription);
        transaction.update(logRef, {
          'xpEarned': earned + xpDelta,
          'completedTasks': tasks,
        });
      }
    });

    final userDoc = await _userDoc(uid).get();
    if (userDoc.exists) {
      final user = UserModel.fromFirestore(userDoc);
      await _syncProfileProjections(user);
      if (leveledUp) {
        await _publishLevelActivityBestEffort(user);
      }
    }

    return leveledUp;
  }

  /// Claim a daily quest exactly once and award its XP/stat reward.
  Future<bool> claimDailyQuest({
    required String uid,
    required String questId,
    required int xpDelta,
    Map<String, int> statDeltas = const {},
    required String taskDescription,
  }) async {
    var claimed = false;
    var leveledUp = false;
    final currentWeek = AppDateUtils.weekKey();

    await _db.runTransaction((transaction) async {
      final userRef = _userDoc(uid);
      final today = AppDateUtils.todayKey();
      final logRef = _dailyLogs(uid).doc(today);
      final leaderboardRef = _leaderboardEntry(currentWeek, uid);

      final userDoc = await transaction.get(userRef);
      final logDoc = await transaction.get(logRef);
      if (!userDoc.exists || !logDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final logData = logDoc.data() as Map<String, dynamic>? ?? {};
      final claimedQuestIds = List<String>.from(
        logData['claimedQuestIds'] ?? [],
      );

      if (claimedQuestIds.contains(questId)) return;

      final reward = _calculateRewardUpdate(
        userData: userData,
        xpDelta: xpDelta,
        statDeltas: statDeltas,
        currentWeek: currentWeek,
      );
      leveledUp = reward.leveledUp;
      _writeRewardUpdates(
        transaction: transaction,
        userRef: userRef,
        leaderboardRef: leaderboardRef,
        uid: uid,
        userData: userData,
        reward: reward,
        currentWeek: currentWeek,
      );

      claimedQuestIds.add(questId);
      final tasks = List<String>.from(logData['completedTasks'] ?? []);
      tasks.add(taskDescription);
      transaction.update(logRef, {
        'claimedQuestIds': claimedQuestIds,
        'xpEarned': ((logData['xpEarned'] as num?)?.toInt() ?? 0) + xpDelta,
        'completedTasks': tasks,
      });

      claimed = true;
    });

    final userDoc = await _userDoc(uid).get();
    if (userDoc.exists) {
      final user = UserModel.fromFirestore(userDoc);
      await _syncProfileProjections(user);
      if (leveledUp) {
        await _publishLevelActivityBestEffort(user);
      }
    }

    if (claimed) {
      await _unlockQuestAchievements(uid, questId, QuestCadence.daily);
    }

    return claimed;
  }

  /// Claim a weekly quest exactly once and award its XP/stat reward.
  Future<bool> claimWeeklyQuest({
    required String uid,
    required String questId,
    required int xpDelta,
    Map<String, int> statDeltas = const {},
    required String taskDescription,
  }) async {
    var claimed = false;
    var leveledUp = false;
    final currentWeek = AppDateUtils.weekKey();

    await _db.runTransaction((transaction) async {
      final userRef = _userDoc(uid);
      final logRef = _weeklyQuestLogs(uid).doc(currentWeek);
      final leaderboardRef = _leaderboardEntry(currentWeek, uid);

      final userDoc = await transaction.get(userRef);
      final logDoc = await transaction.get(logRef);
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final logData = logDoc.data() as Map<String, dynamic>? ?? {};
      final claimedQuestIds = List<String>.from(
        logData['claimedQuestIds'] ?? [],
      );

      if (claimedQuestIds.contains(questId)) return;

      final reward = _calculateRewardUpdate(
        userData: userData,
        xpDelta: xpDelta,
        statDeltas: statDeltas,
        currentWeek: currentWeek,
      );
      leveledUp = reward.leveledUp;
      _writeRewardUpdates(
        transaction: transaction,
        userRef: userRef,
        leaderboardRef: leaderboardRef,
        uid: uid,
        userData: userData,
        reward: reward,
        currentWeek: currentWeek,
      );

      claimedQuestIds.add(questId);
      final tasks = List<String>.from(logData['completedTasks'] ?? []);
      tasks.add(taskDescription);
      transaction.set(logRef, {
        'weekKey': currentWeek,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'claimedQuestIds': claimedQuestIds,
        'xpEarned': ((logData['xpEarned'] as num?)?.toInt() ?? 0) + xpDelta,
        'completedTasks': tasks,
      }, SetOptions(merge: true));

      claimed = true;
    });

    final userDoc = await _userDoc(uid).get();
    if (userDoc.exists) {
      final user = UserModel.fromFirestore(userDoc);
      await _syncProfileProjections(user);
      if (leveledUp) {
        await _publishLevelActivityBestEffort(user);
      }
    }

    if (claimed) {
      await _unlockQuestAchievements(uid, questId, QuestCadence.weekly);
    }

    return claimed;
  }

  // ─── Streak ───────────────────────────────────────────────

  /// Update streak logic on app open
  Future<void> updateStreak(String uid) async {
    var streakChanged = false;

    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(_userDoc(uid));
      if (!userDoc.exists) return;

      final data = userDoc.data() as Map<String, dynamic>;
      final lastActive =
          (data['lastActiveDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      final streak = (data['streakDays'] as num?)?.toInt() ?? 0;
      final now = DateTime.now();

      int newStreak = streak;
      if (AppDateUtils.isYesterday(lastActive)) {
        newStreak = streak + 1;
      } else if (!AppDateUtils.isToday(lastActive)) {
        newStreak = 1; // Reset — gap of 2+ days
      }
      // If today → no change
      streakChanged = newStreak != streak;

      transaction.update(_userDoc(uid), {
        'streakDays': newStreak,
        'lastActiveDate': Timestamp.fromDate(now),
      });
    });

    final userDoc = await _userDoc(uid).get();
    if (userDoc.exists) {
      final user = UserModel.fromFirestore(userDoc);
      await _syncProfileProjections(user);
      if (streakChanged) {
        await _publishStreakActivityBestEffort(user);
      }
    }
  }

  // ─── Daily Log ────────────────────────────────────────────

  /// Stream today's daily log
  Stream<DailyLogModel?> dailyLogStream(String uid, String dateKey) {
    return _dailyLogs(uid).doc(dateKey).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DailyLogModel.fromFirestore(doc);
    });
  }

  /// Stream the current user's weekly quest log.
  Stream<WeeklyQuestLogModel?> weeklyQuestLogStream(
    String uid,
    String weekKey,
  ) {
    return _weeklyQuestLogs(uid).doc(weekKey).snapshots().map((doc) {
      if (!doc.exists) return null;
      return WeeklyQuestLogModel.fromFirestore(doc);
    });
  }

  /// Ensure today's log exists
  Future<void> ensureTodayLog(String uid) async {
    final today = AppDateUtils.todayKey();
    final doc = await _dailyLogs(uid).doc(today).get();
    if (!doc.exists) {
      await _dailyLogs(
        uid,
      ).doc(today).set(DailyLogModel.empty(today).toFirestore());
    }
  }

  /// Ensure this week's quest log exists.
  Future<void> ensureWeeklyQuestLog(String uid, String weekKey) async {
    final doc = await _weeklyQuestLogs(uid).doc(weekKey).get();
    if (!doc.exists) {
      await _weeklyQuestLogs(
        uid,
      ).doc(weekKey).set(WeeklyQuestLogModel.empty(weekKey).toFirestore());
    }
  }

  /// Update daily log fields
  Future<void> updateDailyLog(
    String uid,
    String dateKey,
    Map<String, dynamic> data,
  ) async {
    await _dailyLogs(uid).doc(dateKey).update(data);
    if (data.containsKey('stepCount') || data.containsKey('waterGlasses')) {
      await _syncChallengeContributionsBestEffort(uid, dateKey);
    }
  }

  /// Calculate and update daily score
  Future<void> updateDailyScore(
    String uid, {
    required int stepGoal,
    required int waterGoal,
  }) async {
    final today = AppDateUtils.todayKey();
    final doc = await _dailyLogs(uid).doc(today).get();
    if (!doc.exists) return;

    final log = DailyLogModel.fromFirestore(doc);
    final stepsScore = (log.stepCount / stepGoal * 40).clamp(0, 40).toInt();
    final mealsScore = (log.mealsLogged * 20).clamp(0, 20);
    final waterScore = (log.waterGlasses / waterGoal * 20).clamp(0, 20).toInt();
    final streakBonus = 20; // full bonus if active today

    final score = (stepsScore + mealsScore + waterScore + streakBonus).clamp(
      0,
      100,
    );

    await _dailyLogs(uid).doc(today).update({'dailyScore': score});
  }

  // ─── Meals ────────────────────────────────────────────────

  /// Save a meal
  Future<void> saveMeal(String uid, MealModel meal) async {
    await _meals(uid).add(meal.toFirestore());

    // Increment meals logged and calories in today's log
    final today = AppDateUtils.todayKey();
    final logRef = _dailyLogs(uid).doc(today);
    await _db.runTransaction((transaction) async {
      final logDoc = await transaction.get(logRef);
      if (logDoc.exists) {
        final data = logDoc.data() as Map<String, dynamic>? ?? {};
        transaction.update(logRef, {
          'mealsLogged': ((data['mealsLogged'] as num?)?.toInt() ?? 0) + 1,
          'caloriesConsumed':
              ((data['caloriesConsumed'] as num?)?.toInt() ?? 0) +
              meal.calories,
        });
      }
    });
  }

  /// Stream meals for today
  Stream<List<MealModel>> mealsStream(String uid) {
    return _meals(uid)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => MealModel.fromFirestore(d)).toList(),
        );
  }

  // ─── Chat ─────────────────────────────────────────────────

  /// Save chat message
  Future<void> saveChatMessage(String uid, ChatMessageModel message) async {
    await _chatHistory(uid).add(message.toFirestore());
  }

  /// Stream chat messages
  Stream<List<ChatMessageModel>> chatMessagesStream(String uid) {
    return _chatHistory(uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ChatMessageModel.fromFirestore(d)).toList(),
        );
  }

  /// Get last N messages for context
  Future<List<ChatMessageModel>> getRecentMessages(
    String uid,
    int limit,
  ) async {
    final snap = await _chatHistory(
      uid,
    ).orderBy('timestamp', descending: true).limit(limit).get();
    return snap.docs
        .map((d) => ChatMessageModel.fromFirestore(d))
        .toList()
        .reversed
        .toList();
  }

  /// Clear entire chat history
  Future<void> clearChatHistory(String uid) async {
    final snap = await _chatHistory(uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ─── Achievements ─────────────────────────────────────────

  /// Stream achievements
  Stream<List<AchievementModel>> achievementsStream(String uid) {
    return _achievements(uid)
        .orderBy('unlockedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AchievementModel.fromFirestore(d)).toList(),
        );
  }

  /// Unlock an achievement
  Future<void> unlockAchievement(
    String uid,
    AchievementModel achievement,
  ) async {
    await _achievements(uid).doc(achievement.id).set(achievement.toFirestore());
    await _publishAchievementActivityBestEffort(uid, achievement);
  }

  /// Unlock an achievement only if it has not been unlocked yet.
  Future<bool> unlockAchievementIfMissing(
    String uid,
    AchievementDefinition definition,
  ) async {
    var unlocked = false;
    final achievementRef = _achievements(uid).doc(definition.id);
    final achievement = definition.unlock();

    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(achievementRef);
      if (doc.exists) return;

      transaction.set(achievementRef, achievement.toFirestore());
      unlocked = true;
    });

    if (unlocked) {
      await _publishAchievementActivityBestEffort(uid, achievement);
    }
    return unlocked;
  }

  // ─── Friends ──────────────────────────────────────────────

  Stream<List<FriendshipModel>> friendshipsStream(String uid) {
    return _friendships()
        .where('participantUids', arrayContains: uid)
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map((doc) => FriendshipModel.fromFirestore(doc))
              .toList();
          items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return items;
        });
  }

  /// Stream accepted friends.
  Stream<List<FriendshipModel>> friendsStream(String uid) {
    return friendshipsStream(
      uid,
    ).map((items) => items.where((item) => item.isAccepted).toList());
  }

  /// Stream pending friend requests received by the current user.
  Stream<List<FriendshipModel>> friendRequestsStream(String uid) {
    return friendshipsStream(
      uid,
    ).map((items) => items.where((item) => item.isIncomingFor(uid)).toList());
  }

  /// Stream pending friend requests sent by the current user.
  Stream<List<FriendshipModel>> sentFriendRequestsStream(String uid) {
    return friendshipsStream(
      uid,
    ).map((items) => items.where((item) => item.isOutgoingFor(uid)).toList());
  }

  /// Get a user's public stats for leaderboard
  Future<Map<String, dynamic>?> getUserPublicStats(String uid) async {
    var data = <String, dynamic>{};
    try {
      final doc = await _publicProfile(uid).get();
      if (doc.exists) {
        data = doc.data() as Map<String, dynamic>? ?? {};
      }
    } on FirebaseException {
      data = {};
    }

    if (data.isEmpty) {
      try {
        final doc = await _userDoc(uid).get();
        if (doc.exists) {
          data = doc.data() as Map<String, dynamic>? ?? {};
        }
      } on FirebaseException {
        data = {};
      }
    }

    if (data.isEmpty) return null;
    return {
      'displayName': data['displayName'] ?? '',
      'currentLevel': data['currentLevel'] ?? 1,
      'xp': data['xp'] ?? 0,
      'streakDays': data['streakDays'] ?? 0,
      'currentClass': data['currentClass'] ?? 'Novice',
      'weeklyXp': data['weeklyXp'] ?? 0,
      'weeklyXpWeek': data['weeklyXpWeek'] ?? '',
    };
  }

  // ─── Weekly League ────────────────────────────────────────

  /// Toggle public weekly leaderboard visibility for the current user.
  Future<void> setLeaderboardOptIn(String uid, bool enabled) async {
    final currentWeek = AppDateUtils.weekKey();

    await _db.runTransaction((transaction) async {
      final userRef = _userDoc(uid);
      final leaderboardRef = _leaderboardEntry(currentWeek, uid);
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      var weeklyXp = (data['weeklyXp'] as num?)?.toInt() ?? 0;
      var weeklyXpWeek = data['weeklyXpWeek'] as String? ?? '';
      if (weeklyXpWeek != currentWeek) {
        weeklyXp = 0;
        weeklyXpWeek = currentWeek;
      }

      transaction.update(userRef, {
        'leaderboardOptIn': enabled,
        'weeklyXp': weeklyXp,
        'weeklyXpWeek': weeklyXpWeek,
      });

      if (enabled) {
        transaction.set(leaderboardRef, {
          'uid': uid,
          'displayName': data['displayName'] ?? '',
          'currentLevel': data['currentLevel'] ?? 1,
          'currentClass': data['currentClass'] ?? 'Novice',
          'weeklyXp': weeklyXp,
          'weekKey': currentWeek,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        transaction.delete(leaderboardRef);
      }
    });

    final userDoc = await _userDoc(uid).get();
    if (userDoc.exists) {
      await _syncProfileProjections(UserModel.fromFirestore(userDoc));
    }
  }

  /// Stream public entries for the current weekly league.
  Stream<List<Map<String, dynamic>>> weeklyLeaderboardStream({
    int limit = 50,
    String? weekKey,
  }) {
    final key = weekKey ?? AppDateUtils.weekKey();
    return _leaderboardEntries(key)
        .orderBy('weeklyXp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return {...data, 'uid': data['uid'] ?? doc.id};
          }).toList(),
        );
  }

  /// Query public entries for the current weekly league once.
  Future<List<Map<String, dynamic>>> getWeeklyLeaderboard({
    int limit = 50,
    String? weekKey,
  }) async {
    final key = weekKey ?? AppDateUtils.weekKey();
    final snap = await _leaderboardEntries(
      key,
    ).orderBy('weeklyXp', descending: true).limit(limit).get();

    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return {...data, 'uid': data['uid'] ?? doc.id};
    }).toList();
  }

  // ─── Sleep ────────────────────────────────────────────────

  /// Update sleep data in today's log
  Future<void> updateSleepData(
    String uid,
    String dateKey,
    double hours,
    String quality,
  ) async {
    await _dailyLogs(
      uid,
    ).doc(dateKey).update({'sleepHours': hours, 'sleepQuality': quality});
  }

  // ─── Weekly Logs ──────────────────────────────────────────

  /// Get last 7 days of daily logs for charts
  Future<List<DailyLogModel>> getWeeklyLogs(String uid) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final startKey = AppDateUtils.formatDate(weekAgo);

    final snap = await _dailyLogs(uid)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
        .orderBy(FieldPath.documentId)
        .get();
    return snap.docs.map((d) => DailyLogModel.fromFirestore(d)).toList();
  }

  /// Get logs for the current ISO week, Monday through Sunday.
  Future<List<DailyLogModel>> getCurrentWeekLogs(
    String uid, {
    DateTime? date,
  }) async {
    final startKey = AppDateUtils.formatDate(AppDateUtils.startOfIsoWeek(date));
    final endKey = AppDateUtils.formatDate(AppDateUtils.endOfIsoWeek(date));

    final snap = await _dailyLogs(uid)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
        .orderBy(FieldPath.documentId)
        .get();
    return snap.docs.map((d) => DailyLogModel.fromFirestore(d)).toList();
  }

  // ─── Today's Meals for Macro Tracking ─────────────────────

  /// Stream meals for today only
  Stream<List<MealModel>> todayMealsStream(String uid) {
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return _meals(uid)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
        )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => MealModel.fromFirestore(d)).toList(),
        );
  }

  _RewardUpdate _calculateRewardUpdate({
    required Map<String, dynamic> userData,
    required int xpDelta,
    required Map<String, int> statDeltas,
    required String currentWeek,
  }) {
    var currentXp = (userData['xp'] as num?)?.toInt() ?? 0;
    var currentLevel = (userData['currentLevel'] as num?)?.toInt() ?? 1;
    var xpToNext = (userData['xpToNextLevel'] as num?)?.toInt() ?? 500;
    var weeklyXp = (userData['weeklyXp'] as num?)?.toInt() ?? 0;
    var weeklyXpWeek = userData['weeklyXpWeek'] as String? ?? '';
    var leveledUp = false;

    currentXp += xpDelta;
    if (weeklyXpWeek != currentWeek) {
      weeklyXp = 0;
      weeklyXpWeek = currentWeek;
    }
    weeklyXp += xpDelta;

    while (currentXp >= xpToNext) {
      currentXp -= xpToNext;
      currentLevel++;
      xpToNext = UserModel.xpForLevel(currentLevel);
      leveledUp = true;
    }

    final stats = userData['stats'] as Map<String, dynamic>? ?? {};
    final updatedStats = Map<String, dynamic>.from(stats);
    for (final entry in statDeltas.entries) {
      final current = (updatedStats[entry.key] as num?)?.toInt() ?? 0;
      updatedStats[entry.key] = current + entry.value;
    }

    return _RewardUpdate(
      currentXp: currentXp,
      currentLevel: currentLevel,
      xpToNextLevel: xpToNext,
      currentClass: UserModel.classForLevel(currentLevel),
      weeklyXp: weeklyXp,
      weeklyXpWeek: weeklyXpWeek,
      stats: updatedStats,
      leveledUp: leveledUp,
    );
  }

  void _writeRewardUpdates({
    required Transaction transaction,
    required DocumentReference userRef,
    required DocumentReference leaderboardRef,
    required String uid,
    required Map<String, dynamic> userData,
    required _RewardUpdate reward,
    required String currentWeek,
  }) {
    transaction.update(userRef, {
      'xp': reward.currentXp,
      'currentLevel': reward.currentLevel,
      'xpToNextLevel': reward.xpToNextLevel,
      'currentClass': reward.currentClass,
      'weeklyXp': reward.weeklyXp,
      'weeklyXpWeek': reward.weeklyXpWeek,
      'stats': reward.stats,
    });

    final leaderboardOptIn = userData['leaderboardOptIn'] as bool? ?? false;
    if (leaderboardOptIn) {
      transaction.set(leaderboardRef, {
        'uid': uid,
        'displayName': userData['displayName'] ?? '',
        'currentLevel': reward.currentLevel,
        'currentClass': reward.currentClass,
        'weeklyXp': reward.weeklyXp,
        'weekKey': currentWeek,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  Future<void> _unlockQuestAchievements(
    String uid,
    String questId,
    QuestCadence cadence,
  ) async {
    await unlockAchievementIfMissing(uid, AchievementCatalog.firstQuest);

    if (cadence == QuestCadence.daily && questId == DailyQuestIds.combo) {
      await unlockAchievementIfMissing(uid, AchievementCatalog.dailyCombo);
    }

    if (cadence == QuestCadence.weekly) {
      await unlockAchievementIfMissing(
        uid,
        AchievementCatalog.firstWeeklyQuest,
      );
      switch (questId) {
        case WeeklyQuestIds.combo:
          await unlockAchievementIfMissing(uid, AchievementCatalog.weeklyCombo);
          break;
        case WeeklyQuestIds.steps:
          await unlockAchievementIfMissing(uid, AchievementCatalog.weeklySteps);
          break;
        case WeeklyQuestIds.hydration:
          await unlockAchievementIfMissing(
            uid,
            AchievementCatalog.weeklyHydration,
          );
          break;
        case WeeklyQuestIds.nutrition:
          await unlockAchievementIfMissing(
            uid,
            AchievementCatalog.weeklyNutrition,
          );
          break;
      }
    }
  }

  Map<String, dynamic> _publicProfileData(UserModel user) => {
    'uid': user.uid,
    'displayName': user.displayName,
    'email': user.email,
    'emailLower': user.email.toLowerCase(),
    'avatarUrl': user.avatarUrl,
    'currentLevel': user.currentLevel,
    'currentClass': user.currentClass,
    'xp': user.xp,
    'streakDays': user.streakDays,
    'weeklyXp': user.weeklyXp,
    'weeklyXpWeek': user.weeklyXpWeek,
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  };

  Map<String, dynamic> _friendProfileData(UserModel user) => {
    'uid': user.uid,
    'age': user.age,
    'dailyGoals': user.dailyGoals.toMap(),
    'socialEnergyLevel': user.socialEnergyLevel,
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  };

  Map<String, dynamic> _userSearchData(UserModel user) => {
    'uid': user.uid,
    'displayName': user.displayName,
    'email': user.email,
    'emailLower': user.email.toLowerCase(),
    'avatarUrl': user.avatarUrl,
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  };

  Future<void> _syncProfileProjections(UserModel user) async {
    await _setBestEffort(_publicProfile(user.uid), _publicProfileData(user));
    await _setBestEffort(_friendProfile(user.uid), _friendProfileData(user));
    if (user.email.isNotEmpty) {
      await _setBestEffort(_userSearchDoc(user.email), _userSearchData(user));
    }
  }

  Future<void> _setBestEffort(
    DocumentReference ref,
    Map<String, dynamic> data,
  ) async {
    try {
      await ref.set(data, SetOptions(merge: true));
    } on FirebaseException {
      // Projection writes are helpful for search/public profile discovery, but
      // the private profile save should not fail if deployed rules lag behind.
    }
  }

  Future<void> syncMilestoneActivities(String uid) async {
    try {
      final userDoc = await _userDoc(uid).get();
      if (!userDoc.exists) return;

      var user = UserModel.fromFirestore(userDoc);
      if (!user.shareMilestones) return;

      await _ensureSocialProfileFields(user);
      final refreshed = await _userDoc(uid).get();
      if (refreshed.exists) {
        user = UserModel.fromFirestore(refreshed);
      }

      if (user.currentLevel > 1) {
        await _publishLevelActivityBestEffort(user);
      }
      if (isStreakMilestone(user.streakDays)) {
        await _publishStreakActivityBestEffort(user);
      }

      final achievementDocs = await _achievements(uid).get();
      for (final achievementDoc in achievementDocs.docs) {
        await _publishAchievementActivityBestEffort(
          uid,
          AchievementModel.fromFirestore(achievementDoc),
        );
      }
    } catch (error) {
      debugPrint('Social milestone sync failed for $uid: $error');
    }
  }

  Future<UserModel> _ensureSocialProfileFields(UserModel user) async {
    final normalizedClass = UserModel.classForLevel(user.currentLevel);
    await _userDoc(user.uid).set({
      'avatarUrl': user.avatarUrl,
      'currentClass': normalizedClass,
      'xp': user.xp,
      'xpToNextLevel': user.xpToNextLevel,
      'shareMilestones': user.shareMilestones,
    }, SetOptions(merge: true));

    return user.copyWith(currentClass: normalizedClass);
  }

  Future<void> _syncChallengeContributionsBestEffort(
    String uid,
    String logId,
  ) async {
    try {
      final log = await _dailyLogs(uid).doc(logId).get();
      if (!log.exists) return;
      final logData = log.data() as Map<String, dynamic>? ?? {};
      final challenges = await _db
          .collection('social_challenges')
          .where('participants', arrayContains: uid)
          .get();

      for (final challenge in challenges.docs) {
        final challengeData = challenge.data();
        final observedAmount = switch (challengeData['type']) {
          'steps' => (logData['stepCount'] as num?)?.toInt() ?? 0,
          'water' => (logData['waterGlasses'] as num?)?.toInt() ?? 0,
          _ => 0,
        };
        if (observedAmount <= 0) continue;

        final contributionRef = challenge.reference
            .collection('progressContributions')
            .doc('${uid}_$logId');
        try {
          await _db.runTransaction((transaction) async {
            final existing = await transaction.get(contributionRef);
            final creditedAmount = existing.exists
                ? ((existing.data()?['creditedAmount'] as num?)?.toInt() ?? 0)
                : 0;
            if (observedAmount <= creditedAmount) return;

            transaction.set(contributionRef, {
              'challengeId': challenge.id,
              'userId': uid,
              'logId': logId,
              'creditedAmount': observedAmount,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          });
        } catch (_) {
          // Challenge progress is secondary to the user's private daily log.
        }
      }
    } catch (_) {
      // Daily tracking must keep working if social collections are unavailable.
    }
  }

  Future<void> _publishStreakActivityBestEffort(UserModel user) async {
    if (!isStreakMilestone(user.streakDays)) return;
    await _publishActivityBestEffort(
      activityId: 'streak_${user.uid}_${user.streakDays}',
      user: user,
      type: 'streak_milestone',
      title: '🔥 ${user.streakDays} Günlük Seri!',
      description:
          '${user.displayName}, ${user.streakDays} günlük seriye ulaştı.',
      metadata: {'days': user.streakDays},
    );
  }

  Future<void> _publishLevelActivityBestEffort(UserModel user) async {
    final className = UserModel.classForLevel(user.currentLevel);
    await _publishActivityBestEffort(
      activityId: 'level_${user.uid}_${user.currentLevel}',
      user: user,
      type: 'level_up',
      title: 'Seviye ${user.currentLevel}!',
      description:
          '${user.displayName}, ${user.currentLevel}. seviyeye yükseldi.',
      metadata: {'level': user.currentLevel, 'className': className},
    );
  }

  Future<void> _publishAchievementActivityBestEffort(
    String uid,
    AchievementModel achievement,
  ) async {
    try {
      final userDoc = await _userDoc(uid).get();
      if (!userDoc.exists) return;
      final user = UserModel.fromFirestore(userDoc);
      await _publishActivityBestEffort(
        activityId: 'achievement_${user.uid}_${achievement.id}',
        user: user,
        type: 'achievement_unlocked',
        title: '${achievement.icon} ${achievement.title}',
        description:
            '${user.displayName}, "${achievement.title}" başarısını açtı.',
        metadata: {
          'achievementId': achievement.id,
          'achievementTitle': achievement.title,
          'icon': achievement.icon,
        },
      );
    } catch (_) {
      // Achievement unlocks remain valid if the social feed is unavailable.
    }
  }

  Future<void> _publishActivityBestEffort({
    required String activityId,
    required UserModel user,
    required String type,
    required String title,
    required String description,
    required Map<String, dynamic> metadata,
  }) async {
    if (!user.shareMilestones) return;

    try {
      final activityRef = _socialActivity(activityId);
      try {
        final existing = await activityRef.get();
        if (existing.exists) return;
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied') rethrow;
      }

      final normalizedUser = await _ensureSocialProfileFields(user);
      await activityRef.set({
        'type': type,
        'actorUid': normalizedUser.uid,
        'actorDisplayName': normalizedUser.displayName,
        'actorAvatarUrl': normalizedUser.avatarUrl,
        'title': title,
        'description': description,
        'metadata': metadata,
        'visibility': 'friends',
        'createdAt': FieldValue.serverTimestamp(),
        'isSpecialAchievement': true,
      });
    } on FirebaseException catch (error) {
      debugPrint(
        'Social activity $activityId was not published: '
        '${error.code} ${error.message ?? ''}',
      );
    } catch (error) {
      debugPrint('Social activity $activityId was not published: $error');
      // Social sharing is best-effort and must not block primary app actions.
    }
  }

  static bool isStreakMilestone(int days) {
    return const {3, 7, 10, 30, 50, 100}.contains(days) ||
        (days > 100 && days % 100 == 0);
  }
}

class _RewardUpdate {
  final int currentXp;
  final int currentLevel;
  final int xpToNextLevel;
  final String currentClass;
  final int weeklyXp;
  final String weeklyXpWeek;
  final Map<String, dynamic> stats;
  final bool leveledUp;

  const _RewardUpdate({
    required this.currentXp,
    required this.currentLevel,
    required this.xpToNextLevel,
    required this.currentClass,
    required this.weeklyXp,
    required this.weeklyXpWeek,
    required this.stats,
    required this.leveledUp,
  });
}
