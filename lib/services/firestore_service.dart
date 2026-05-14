import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/models/user_model.dart';
import '../shared/models/daily_log_model.dart';
import '../shared/models/meal_model.dart';
import '../shared/models/chat_message_model.dart';
import '../shared/models/achievement_model.dart';
import '../shared/models/friendship_model.dart';
import '../core/utils/date_utils.dart';

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

  CollectionReference _friendships() => _db.collection('friendships');

  DocumentReference _publicProfile(String uid) =>
      _db.collection('publicProfiles').doc(uid);

  CollectionReference _leaderboardEntries(String weekKey) =>
      _db.collection('leaderboards').doc(weekKey).collection('entries');

  DocumentReference _leaderboardEntry(String weekKey, String uid) =>
      _leaderboardEntries(weekKey).doc(uid);

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
    final batch = _db.batch();
    batch.set(_userDoc(uid), user.toFirestore());
    batch.set(_publicProfile(uid), _publicProfileData(user));
    await batch.commit();
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
    if (updates.isNotEmpty) {
      await _userDoc(uid).update(updates);
    }
    final refreshed = await _userDoc(uid).get();
    if (refreshed.exists) {
      await _publicProfile(uid).set(
        _publicProfileData(UserModel.fromFirestore(refreshed)),
        SetOptions(merge: true),
      );
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

  Future<void> updateProfileSettings({
    required String uid,
    required String displayName,
    required int? age,
    required int? heightCm,
    required double? weightKg,
    required DailyGoals dailyGoals,
    required String socialEnergyLevel,
    required bool leaderboardOptIn,
  }) async {
    await _userDoc(uid).update({
      'displayName': displayName,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'dailyGoals': dailyGoals.toMap(),
      'socialEnergyLevel': socialEnergyLevel,
    });

    final doc = await _userDoc(uid).get();
    if (doc.exists) {
      await _publicProfile(uid).set(
        _publicProfileData(UserModel.fromFirestore(doc)),
        SetOptions(merge: true),
      );
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
      int currentXp = (data['xp'] as num?)?.toInt() ?? 0;
      int currentLevel = (data['currentLevel'] as num?)?.toInt() ?? 1;
      int xpToNext = (data['xpToNextLevel'] as num?)?.toInt() ?? 500;
      int weeklyXp = (data['weeklyXp'] as num?)?.toInt() ?? 0;
      String weeklyXpWeek = data['weeklyXpWeek'] as String? ?? '';
      final leaderboardOptIn = data['leaderboardOptIn'] as bool? ?? false;
      final stats = data['stats'] as Map<String, dynamic>? ?? {};

      currentXp += xpDelta;
      if (weeklyXpWeek != currentWeek) {
        weeklyXp = 0;
        weeklyXpWeek = currentWeek;
      }
      weeklyXp += xpDelta;

      // Check for level up
      while (currentXp >= xpToNext) {
        currentXp -= xpToNext;
        currentLevel++;
        xpToNext = UserModel.xpForLevel(currentLevel);
        leveledUp = true;
      }

      final newClass = UserModel.classForLevel(currentLevel);

      // Update stats
      final updatedStats = Map<String, dynamic>.from(stats);
      for (final entry in statDeltas.entries) {
        final current = (updatedStats[entry.key] as num?)?.toInt() ?? 0;
        updatedStats[entry.key] = current + entry.value;
      }

      transaction.update(userRef, {
        'xp': currentXp,
        'currentLevel': currentLevel,
        'xpToNextLevel': xpToNext,
        'currentClass': newClass,
        'weeklyXp': weeklyXp,
        'weeklyXpWeek': weeklyXpWeek,
        'stats': updatedStats,
      });

      transaction.set(_publicProfile(uid), {
        'uid': uid,
        'displayName': data['displayName'] ?? '',
        'avatarUrl': data['avatarUrl'] ?? '',
        'currentLevel': currentLevel,
        'currentClass': newClass,
        'xp': currentXp,
        'streakDays': data['streakDays'] ?? 0,
        'weeklyXp': weeklyXp,
        'weeklyXpWeek': weeklyXpWeek,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));

      if (leaderboardOptIn) {
        transaction.set(leaderboardRef, {
          'uid': uid,
          'displayName': data['displayName'] ?? '',
          'currentLevel': currentLevel,
          'currentClass': newClass,
          'weeklyXp': weeklyXp,
          'weekKey': currentWeek,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

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

      int currentXp = (userData['xp'] as num?)?.toInt() ?? 0;
      int currentLevel = (userData['currentLevel'] as num?)?.toInt() ?? 1;
      int xpToNext = (userData['xpToNextLevel'] as num?)?.toInt() ?? 500;
      int weeklyXp = (userData['weeklyXp'] as num?)?.toInt() ?? 0;
      String weeklyXpWeek = userData['weeklyXpWeek'] as String? ?? '';
      final leaderboardOptIn = userData['leaderboardOptIn'] as bool? ?? false;
      final stats = userData['stats'] as Map<String, dynamic>? ?? {};

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
      }

      final newClass = UserModel.classForLevel(currentLevel);
      final updatedStats = Map<String, dynamic>.from(stats);
      for (final entry in statDeltas.entries) {
        final current = (updatedStats[entry.key] as num?)?.toInt() ?? 0;
        updatedStats[entry.key] = current + entry.value;
      }

      transaction.update(userRef, {
        'xp': currentXp,
        'currentLevel': currentLevel,
        'xpToNextLevel': xpToNext,
        'currentClass': newClass,
        'weeklyXp': weeklyXp,
        'weeklyXpWeek': weeklyXpWeek,
        'stats': updatedStats,
      });

      transaction.set(_publicProfile(uid), {
        'uid': uid,
        'displayName': userData['displayName'] ?? '',
        'avatarUrl': userData['avatarUrl'] ?? '',
        'currentLevel': currentLevel,
        'currentClass': newClass,
        'xp': currentXp,
        'streakDays': userData['streakDays'] ?? 0,
        'weeklyXp': weeklyXp,
        'weeklyXpWeek': weeklyXpWeek,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));

      if (leaderboardOptIn) {
        transaction.set(leaderboardRef, {
          'uid': uid,
          'displayName': userData['displayName'] ?? '',
          'currentLevel': currentLevel,
          'currentClass': newClass,
          'weeklyXp': weeklyXp,
          'weekKey': currentWeek,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

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

    return claimed;
  }

  // ─── Streak ───────────────────────────────────────────────

  /// Update streak logic on app open
  Future<void> updateStreak(String uid) async {
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

      transaction.update(_userDoc(uid), {
        'streakDays': newStreak,
        'lastActiveDate': Timestamp.fromDate(now),
      });
      transaction.set(_publicProfile(uid), {
        'uid': uid,
        'streakDays': newStreak,
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));
    });
  }

  // ─── Daily Log ────────────────────────────────────────────

  /// Stream today's daily log
  Stream<DailyLogModel?> dailyLogStream(String uid, String dateKey) {
    return _dailyLogs(uid).doc(dateKey).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DailyLogModel.fromFirestore(doc);
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

  /// Update daily log fields
  Future<void> updateDailyLog(
    String uid,
    String dateKey,
    Map<String, dynamic> data,
  ) async {
    await _dailyLogs(uid).doc(dateKey).update(data);
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
    final doc = await _publicProfile(uid).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>? ?? {};
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

      transaction.set(_publicProfile(uid), {
        'uid': uid,
        'displayName': data['displayName'] ?? '',
        'avatarUrl': data['avatarUrl'] ?? '',
        'currentLevel': data['currentLevel'] ?? 1,
        'currentClass': data['currentClass'] ?? 'Novice',
        'xp': data['xp'] ?? 0,
        'streakDays': data['streakDays'] ?? 0,
        'weeklyXp': weeklyXp,
        'weeklyXpWeek': weeklyXpWeek,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));

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

  Map<String, dynamic> _publicProfileData(UserModel user) => {
    'uid': user.uid,
    'displayName': user.displayName,
    'avatarUrl': user.avatarUrl,
    'currentLevel': user.currentLevel,
    'currentClass': user.currentClass,
    'xp': user.xp,
    'streakDays': user.streakDays,
    'weeklyXp': user.weeklyXp,
    'weeklyXpWeek': user.weeklyXpWeek,
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  };
}
