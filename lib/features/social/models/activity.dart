import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityFeedItem {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String actionTitle;
  final String actionDescription;
  final DateTime timestamp;
  final bool isSpecialAchievement;
  final List<String> likes;

  ActivityFeedItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.actionTitle,
    required this.actionDescription,
    required this.timestamp,
    this.isSpecialAchievement = false,
    required this.likes,
  });

  factory ActivityFeedItem.fromFirestore(DocumentSnapshot doc) {
    try {
      var data = doc.data() as Map<String, dynamic>;
      return ActivityFeedItem(
        id: doc.id,
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? 'Kullanıcı',
        userAvatarUrl: data['userAvatarUrl'] ?? '',
        actionTitle: data['actionTitle'] ?? '',
        actionDescription: data['actionDescription'] ?? '',
        timestamp:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isSpecialAchievement: data['isSpecialAchievement'] ?? false,
        likes: List<String>.from(data['likes'] ?? []),
      );
    } catch (e) {
      return ActivityFeedItem.empty(doc.id);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'actionTitle': actionTitle,
      'actionDescription': actionDescription,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSpecialAchievement': isSpecialAchievement,
      'likes': likes,
    };
  }

  bool get isLegacyMock =>
      userId == 'mock_user_1' || userId.startsWith('mock_');

  bool get hasProfileLink => userId.isNotEmpty && !isLegacyMock;

  factory ActivityFeedItem.empty(String id) {
    return ActivityFeedItem(
      id: id,
      userId: '',
      userName: 'Hata',
      userAvatarUrl: '',
      actionTitle: 'İçerik yüklenemedi',
      actionDescription: '',
      timestamp: DateTime.now(),
      likes: [],
    );
  }
}
