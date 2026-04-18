import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/models/user_model.dart';
import '../shared/models/daily_log_model.dart';
import '../shared/models/meal_model.dart';
import '../shared/models/chat_message_model.dart';
import '../shared/models/achievement_model.dart';
import '../shared/models/friendship_model.dart';
import '../core/utils/date_utils.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── References ───────────────────────────────────────────

  DocumentReference _userDoc(String uid) => _db.collection('users').doc(uid);

  CollectionReference _dailyLogs(String uid) =>
      _userDoc(uid).collection('dailyLogs');

  CollectionReference _meals(String uid) =>
      _userDoc(uid).collection('meals');

  CollectionReference _chatHistory(String uid) =>
      _userDoc(uid).collection('chatHistory');

  CollectionReference _achievements(String uid) =>
      _userDoc(uid).collection('achievements');

  CollectionReference _friends(String uid) =>
      _userDoc(uid).collection('friends');

  // ─── User ─────────────────────────────────────────────────

  /// Create initial user document with defaults
  Future<void> createUserDoc({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    final user = UserModel(
      uid: uid,
      displayName: displayName,
      email: email,
      createdAt: DateTime.now(),
      lastActiveDate: DateTime.now(),
    );
    await _userDoc(uid).set(user.toFirestore());
  }

  /// Ensure user document exists — create if missing
  Future<void> ensureUserDoc({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) {
      await createUserDoc(uid: uid, displayName: displayName, email: email);
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

  /// Atomic XP and stat update using transaction
  Future<bool> updateUserXP({
    required String uid,
    required int xpDelta,
    Map<String, int> statDeltas = const {},
    String? taskDescription,
  }) async {
    bool leveledUp = false;

    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(_userDoc(uid));
      if (!userDoc.exists) return;

      final data = userDoc.data() as Map<String, dynamic>;
      int currentXp = (data['xp'] as num?)?.toInt() ?? 0;
      int currentLevel = (data['currentLevel'] as num?)?.toInt() ?? 1;
      int xpToNext = (data['xpToNextLevel'] as num?)?.toInt() ?? 500;
      final stats = data['stats'] as Map<String, dynamic>? ?? {};

      currentXp += xpDelta;

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

      transaction.update(_userDoc(uid), {
        'xp': currentXp,
        'currentLevel': currentLevel,
        'xpToNextLevel': xpToNext,
        'currentClass': newClass,
        'stats': updatedStats,
      });

      // Also update today's log xpEarned
      final today = AppDateUtils.todayKey();
      final logRef = _dailyLogs(uid).doc(today);
      final logDoc = await transaction.get(logRef);
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
      await _dailyLogs(uid)
          .doc(today)
          .set(DailyLogModel.empty(today).toFirestore());
    }
  }

  /// Update daily log fields
  Future<void> updateDailyLog(
      String uid, String dateKey, Map<String, dynamic> data) async {
    await _dailyLogs(uid).doc(dateKey).update(data);
  }

  /// Calculate and update daily score
  Future<void> updateDailyScore(String uid, {
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

    final score = (stepsScore + mealsScore + waterScore + streakBonus).clamp(0, 100);

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
              ((data['caloriesConsumed'] as num?)?.toInt() ?? 0) + meal.calories,
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
        .map((snap) =>
            snap.docs.map((d) => MealModel.fromFirestore(d)).toList());
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
        .map((snap) =>
            snap.docs.map((d) => ChatMessageModel.fromFirestore(d)).toList());
  }

  /// Get last N messages for context
  Future<List<ChatMessageModel>> getRecentMessages(
      String uid, int limit) async {
    final snap = await _chatHistory(uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => ChatMessageModel.fromFirestore(d))
        .toList()
        .reversed
        .toList();
  }

  // ─── Achievements ─────────────────────────────────────────

  /// Stream achievements
  Stream<List<AchievementModel>> achievementsStream(String uid) {
    return _achievements(uid)
        .orderBy('unlockedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AchievementModel.fromFirestore(d)).toList());
  }

  /// Unlock an achievement
  Future<void> unlockAchievement(
      String uid, AchievementModel achievement) async {
    await _achievements(uid).doc(achievement.id).set(achievement.toFirestore());
  }

  // ─── Friends ──────────────────────────────────────────────

  /// Send friend request
  Future<void> sendFriendRequest({
    required String fromUid,
    required String fromName,
    required String fromEmail,
    required String toUid,
    required String toName,
    required String toEmail,
  }) async {
    final now = DateTime.now();
    // Add to sender's friends list
    await _friends(fromUid).doc(toUid).set(FriendshipModel(
      friendUid: toUid,
      friendName: toName,
      friendEmail: toEmail,
      status: 'pending',
      createdAt: now,
    ).toFirestore());
    // Add to receiver's friends list
    await _friends(toUid).doc(fromUid).set(FriendshipModel(
      friendUid: fromUid,
      friendName: fromName,
      friendEmail: fromEmail,
      status: 'pending',
      createdAt: now,
    ).toFirestore());
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String uid, String friendUid) async {
    await _friends(uid).doc(friendUid).update({'status': 'accepted'});
    await _friends(friendUid).doc(uid).update({'status': 'accepted'});
  }

  /// Decline / remove friend
  Future<void> removeFriend(String uid, String friendUid) async {
    await _friends(uid).doc(friendUid).delete();
    await _friends(friendUid).doc(uid).delete();
  }

  /// Stream accepted friends
  Stream<List<FriendshipModel>> friendsStream(String uid) {
    return _friends(uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendshipModel.fromFirestore(d)).toList());
  }

  /// Stream pending friend requests (received)
  Stream<List<FriendshipModel>> friendRequestsStream(String uid) {
    return _friends(uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendshipModel.fromFirestore(d)).toList());
  }

  /// Search user by email
  Future<UserModel?> findUserByEmail(String email) async {
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return UserModel.fromFirestore(snap.docs.first);
  }

  /// Get a user's public stats for leaderboard
  Future<Map<String, dynamic>?> getUserPublicStats(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return {
      'displayName': data['displayName'] ?? '',
      'currentLevel': data['currentLevel'] ?? 1,
      'xp': data['xp'] ?? 0,
      'streakDays': data['streakDays'] ?? 0,
      'currentClass': data['currentClass'] ?? 'Novice',
    };
  }

  // ─── Sleep ────────────────────────────────────────────────

  /// Update sleep data in today's log
  Future<void> updateSleepData(
      String uid, String dateKey, double hours, String quality) async {
    await _dailyLogs(uid).doc(dateKey).update({
      'sleepHours': hours,
      'sleepQuality': quality,
    });
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
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return _meals(uid)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MealModel.fromFirestore(d)).toList());
  }
}
