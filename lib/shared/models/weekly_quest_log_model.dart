import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyQuestLogModel {
  final String weekKey;
  final DateTime updatedAt;
  final List<String> claimedQuestIds;
  final int xpEarned;
  final List<String> completedTasks;

  const WeeklyQuestLogModel({
    required this.weekKey,
    required this.updatedAt,
    this.claimedQuestIds = const [],
    this.xpEarned = 0,
    this.completedTasks = const [],
  });

  factory WeeklyQuestLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WeeklyQuestLogModel(
      weekKey: data['weekKey'] as String? ?? doc.id,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      claimedQuestIds:
          (data['claimedQuestIds'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      xpEarned: (data['xpEarned'] as num?)?.toInt() ?? 0,
      completedTasks:
          (data['completedTasks'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'weekKey': weekKey,
    'updatedAt': Timestamp.fromDate(updatedAt),
    'claimedQuestIds': claimedQuestIds,
    'xpEarned': xpEarned,
    'completedTasks': completedTasks,
  };

  WeeklyQuestLogModel copyWith({
    DateTime? updatedAt,
    List<String>? claimedQuestIds,
    int? xpEarned,
    List<String>? completedTasks,
  }) {
    return WeeklyQuestLogModel(
      weekKey: weekKey,
      updatedAt: updatedAt ?? this.updatedAt,
      claimedQuestIds: claimedQuestIds ?? this.claimedQuestIds,
      xpEarned: xpEarned ?? this.xpEarned,
      completedTasks: completedTasks ?? this.completedTasks,
    );
  }

  factory WeeklyQuestLogModel.empty(String weekKey) {
    return WeeklyQuestLogModel(weekKey: weekKey, updatedAt: DateTime.now());
  }
}
