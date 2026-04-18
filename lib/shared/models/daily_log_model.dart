import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLogModel {
  final String date;
  final DateTime timestamp;
  final int stepCount;
  final int caloriesConsumed;
  final int caloriesBurned;
  final int waterGlasses;
  final String mood;
  final List<String> completedTasks;
  final int dailyScore;
  final int xpEarned;
  final int mealsLogged;
  final double sleepHours;
  final String sleepQuality; // good, fair, poor

  const DailyLogModel({
    required this.date,
    required this.timestamp,
    this.stepCount = 0,
    this.caloriesConsumed = 0,
    this.caloriesBurned = 0,
    this.waterGlasses = 0,
    this.mood = '',
    this.completedTasks = const [],
    this.dailyScore = 0,
    this.xpEarned = 0,
    this.mealsLogged = 0,
    this.sleepHours = 0,
    this.sleepQuality = '',
  });

  factory DailyLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DailyLogModel(
      date: doc.id,
      timestamp: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stepCount: (data['stepCount'] as num?)?.toInt() ?? 0,
      caloriesConsumed: (data['caloriesConsumed'] as num?)?.toInt() ?? 0,
      caloriesBurned: (data['caloriesBurned'] as num?)?.toInt() ?? 0,
      waterGlasses: (data['waterGlasses'] as num?)?.toInt() ?? 0,
      mood: data['mood'] as String? ?? '',
      completedTasks: (data['completedTasks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dailyScore: (data['dailyScore'] as num?)?.toInt() ?? 0,
      xpEarned: (data['xpEarned'] as num?)?.toInt() ?? 0,
      mealsLogged: (data['mealsLogged'] as num?)?.toInt() ?? 0,
      sleepHours: (data['sleepHours'] as num?)?.toDouble() ?? 0,
      sleepQuality: data['sleepQuality'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'date': Timestamp.fromDate(timestamp),
        'stepCount': stepCount,
        'caloriesConsumed': caloriesConsumed,
        'caloriesBurned': caloriesBurned,
        'waterGlasses': waterGlasses,
        'mood': mood,
        'completedTasks': completedTasks,
        'dailyScore': dailyScore,
        'xpEarned': xpEarned,
        'mealsLogged': mealsLogged,
        'sleepHours': sleepHours,
        'sleepQuality': sleepQuality,
      };

  DailyLogModel copyWith({
    int? stepCount,
    int? caloriesConsumed,
    int? caloriesBurned,
    int? waterGlasses,
    String? mood,
    List<String>? completedTasks,
    int? dailyScore,
    int? xpEarned,
    int? mealsLogged,
    double? sleepHours,
    String? sleepQuality,
  }) {
    return DailyLogModel(
      date: date,
      timestamp: timestamp,
      stepCount: stepCount ?? this.stepCount,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      waterGlasses: waterGlasses ?? this.waterGlasses,
      mood: mood ?? this.mood,
      completedTasks: completedTasks ?? this.completedTasks,
      dailyScore: dailyScore ?? this.dailyScore,
      xpEarned: xpEarned ?? this.xpEarned,
      mealsLogged: mealsLogged ?? this.mealsLogged,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
    );
  }

  /// Create an empty log for today
  factory DailyLogModel.empty(String dateKey) {
    return DailyLogModel(
      date: dateKey,
      timestamp: DateTime.now(),
    );
  }
}
