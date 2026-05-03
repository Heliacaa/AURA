import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats {
  final int strength;
  final int intelligence;
  final int charisma;
  final int vitality;

  const UserStats({
    this.strength = 0,
    this.intelligence = 0,
    this.charisma = 0,
    this.vitality = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      strength: (map['strength'] as num?)?.toInt() ?? 0,
      intelligence: (map['intelligence'] as num?)?.toInt() ?? 0,
      charisma: (map['charisma'] as num?)?.toInt() ?? 0,
      vitality: (map['vitality'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'strength': strength,
    'intelligence': intelligence,
    'charisma': charisma,
    'vitality': vitality,
  };

  UserStats copyWith({
    int? strength,
    int? intelligence,
    int? charisma,
    int? vitality,
  }) {
    return UserStats(
      strength: strength ?? this.strength,
      intelligence: intelligence ?? this.intelligence,
      charisma: charisma ?? this.charisma,
      vitality: vitality ?? this.vitality,
    );
  }
}

class DailyGoals {
  final int steps;
  final int calories;
  final int waterGlasses;

  const DailyGoals({
    this.steps = 10000,
    this.calories = 2000,
    this.waterGlasses = 8,
  });

  factory DailyGoals.fromMap(Map<String, dynamic> map) {
    return DailyGoals(
      steps: (map['steps'] as num?)?.toInt() ?? 10000,
      calories: (map['calories'] as num?)?.toInt() ?? 2000,
      waterGlasses: (map['waterGlasses'] as num?)?.toInt() ?? 8,
    );
  }

  Map<String, dynamic> toMap() => {
    'steps': steps,
    'calories': calories,
    'waterGlasses': waterGlasses,
  };
}

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final DateTime createdAt;
  final String avatarUrl;
  final int currentLevel;
  final String currentClass;
  final int xp;
  final int xpToNextLevel;
  final int streakDays;
  final DateTime lastActiveDate;
  final UserStats stats;
  final DailyGoals dailyGoals;
  final String socialEnergyLevel;
  final bool leaderboardOptIn;
  final int weeklyXp;
  final String weeklyXpWeek;
  final String? fcmToken;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.createdAt,
    this.avatarUrl = '',
    this.currentLevel = 1,
    this.currentClass = 'Novice',
    this.xp = 0,
    this.xpToNextLevel = 500,
    this.streakDays = 0,
    required this.lastActiveDate,
    this.stats = const UserStats(),
    this.dailyGoals = const DailyGoals(),
    this.socialEnergyLevel = 'Orta',
    this.leaderboardOptIn = false,
    this.weeklyXp = 0,
    this.weeklyXpWeek = '',
    this.fcmToken,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      avatarUrl: data['avatarUrl'] as String? ?? '',
      currentLevel: (data['currentLevel'] as num?)?.toInt() ?? 1,
      currentClass: data['currentClass'] as String? ?? 'Novice',
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      xpToNextLevel: (data['xpToNextLevel'] as num?)?.toInt() ?? 500,
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      lastActiveDate:
          (data['lastActiveDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stats: data['stats'] != null
          ? UserStats.fromMap(data['stats'] as Map<String, dynamic>)
          : const UserStats(),
      dailyGoals: data['dailyGoals'] != null
          ? DailyGoals.fromMap(data['dailyGoals'] as Map<String, dynamic>)
          : const DailyGoals(),
      socialEnergyLevel: data['socialEnergyLevel'] as String? ?? 'Orta',
      leaderboardOptIn: data['leaderboardOptIn'] as bool? ?? false,
      weeklyXp: (data['weeklyXp'] as num?)?.toInt() ?? 0,
      weeklyXpWeek: data['weeklyXpWeek'] as String? ?? '',
      fcmToken: data['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'displayName': displayName,
    'email': email,
    'createdAt': Timestamp.fromDate(createdAt),
    'avatarUrl': avatarUrl,
    'currentLevel': currentLevel,
    'currentClass': currentClass,
    'xp': xp,
    'xpToNextLevel': xpToNextLevel,
    'streakDays': streakDays,
    'lastActiveDate': Timestamp.fromDate(lastActiveDate),
    'stats': stats.toMap(),
    'dailyGoals': dailyGoals.toMap(),
    'socialEnergyLevel': socialEnergyLevel,
    'leaderboardOptIn': leaderboardOptIn,
    'weeklyXp': weeklyXp,
    'weeklyXpWeek': weeklyXpWeek,
    if (fcmToken != null) 'fcmToken': fcmToken,
  };

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    int? currentLevel,
    String? currentClass,
    int? xp,
    int? xpToNextLevel,
    int? streakDays,
    DateTime? lastActiveDate,
    UserStats? stats,
    DailyGoals? dailyGoals,
    String? socialEnergyLevel,
    bool? leaderboardOptIn,
    int? weeklyXp,
    String? weeklyXpWeek,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      createdAt: createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentLevel: currentLevel ?? this.currentLevel,
      currentClass: currentClass ?? this.currentClass,
      xp: xp ?? this.xp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      stats: stats ?? this.stats,
      dailyGoals: dailyGoals ?? this.dailyGoals,
      socialEnergyLevel: socialEnergyLevel ?? this.socialEnergyLevel,
      leaderboardOptIn: leaderboardOptIn ?? this.leaderboardOptIn,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      weeklyXpWeek: weeklyXpWeek ?? this.weeklyXpWeek,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  /// Class icon based on class name
  String get classIcon {
    switch (currentClass) {
      case 'Novice':
        return '🌱';
      case 'Warrior':
        return '🛡️';
      case 'Mage':
        return '🧙';
      case 'Champion':
        return '⚔️';
      case 'Legend':
        return '👑';
      default:
        return '🌱';
    }
  }

  /// XP thresholds for each level
  static const List<int> levelThresholds = [
    0,
    500,
    1200,
    2500,
    5000,
    10000,
    18000,
    28000,
    40000,
    55000,
    75000,
    100000,
    130000,
    165000,
    205000,
    250000,
    300000,
    360000,
    430000,
    510000,
    600000,
    700000,
    810000,
    930000,
    1060000,
    1200000,
    1350000,
    1510000,
    1680000,
    1860000,
    2050000,
    2250000,
    2460000,
    2680000,
    2910000,
  ];

  /// Get class name for a given level
  static String classForLevel(int level) {
    if (level >= 35) return 'Legend';
    if (level >= 20) return 'Champion';
    if (level >= 10) return 'Mage';
    if (level >= 5) return 'Warrior';
    return 'Novice';
  }

  /// Get XP needed for a given level
  static int xpForLevel(int level) {
    if (level < 0) return 0;
    if (level >= levelThresholds.length) {
      return levelThresholds.last +
          (level - levelThresholds.length + 1) * 200000;
    }
    return levelThresholds[level];
  }
}
