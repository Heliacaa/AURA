import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final DateTime unlockedAt;
  final String icon;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.unlockedAt,
    required this.icon,
  });

  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AchievementModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      unlockedAt:
          (data['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      icon: data['icon'] as String? ?? '🏆',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'title': title,
        'description': description,
        'unlockedAt': Timestamp.fromDate(unlockedAt),
        'icon': icon,
      };
}
