import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  streakMilestone('streak_milestone'),
  levelUp('level_up'),
  achievementUnlocked('achievement_unlocked'),
  communityChallengeCompleted('community_challenge_completed'),
  unknown('unknown');

  const ActivityType(this.firestoreValue);

  final String firestoreValue;

  static ActivityType fromValue(String? value) {
    return ActivityType.values.firstWhere(
      (type) => type.firestoreValue == value,
      orElse: () => ActivityType.unknown,
    );
  }
}

class ActivityFeedItem {
  final String id;
  final ActivityType type;
  final String actorUid;
  final String actorDisplayName;
  final String actorAvatarUrl;
  final String title;
  final String description;
  final Map<String, dynamic> metadata;
  final String visibility;
  final DateTime createdAt;
  final bool isSpecialAchievement;
  final bool isLikedByCurrentUser;

  const ActivityFeedItem({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.actorDisplayName,
    required this.actorAvatarUrl,
    required this.title,
    required this.description,
    required this.metadata,
    required this.visibility,
    required this.createdAt,
    required this.isSpecialAchievement,
    this.isLikedByCurrentUser = false,
  });

  factory ActivityFeedItem.fromFirestore(
    DocumentSnapshot doc, {
    bool isLikedByCurrentUser = false,
  }) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return ActivityFeedItem(
        id: doc.id,
        type: ActivityType.fromValue(data['type'] as String?),
        actorUid:
            data['actorUid'] as String? ?? data['userId'] as String? ?? '',
        actorDisplayName:
            data['actorDisplayName'] as String? ??
            data['userName'] as String? ??
            'AURA Kullanıcısı',
        actorAvatarUrl:
            data['actorAvatarUrl'] as String? ??
            data['userAvatarUrl'] as String? ??
            '',
        title: data['title'] as String? ?? data['actionTitle'] as String? ?? '',
        description:
            data['description'] as String? ??
            data['actionDescription'] as String? ??
            '',
        metadata: Map<String, dynamic>.from(data['metadata'] ?? const {}),
        visibility: data['visibility'] as String? ?? 'global',
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ??
            (data['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        isSpecialAchievement: data['isSpecialAchievement'] as bool? ?? false,
        isLikedByCurrentUser: isLikedByCurrentUser,
      );
    } catch (_) {
      return ActivityFeedItem.empty(doc.id);
    }
  }

  ActivityFeedItem copyWith({bool? isLikedByCurrentUser}) {
    return ActivityFeedItem(
      id: id,
      type: type,
      actorUid: actorUid,
      actorDisplayName: actorDisplayName,
      actorAvatarUrl: actorAvatarUrl,
      title: title,
      description: description,
      metadata: metadata,
      visibility: visibility,
      createdAt: createdAt,
      isSpecialAchievement: isSpecialAchievement,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }

  factory ActivityFeedItem.empty(String id) {
    return ActivityFeedItem(
      id: id,
      type: ActivityType.unknown,
      actorUid: '',
      actorDisplayName: 'Hata',
      actorAvatarUrl: '',
      title: 'İçerik yüklenemedi',
      description: '',
      metadata: const {},
      visibility: 'global',
      createdAt: DateTime.now(),
      isSpecialAchievement: false,
    );
  }
}
