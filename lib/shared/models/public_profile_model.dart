import 'package:cloud_firestore/cloud_firestore.dart';

class PublicProfileModel {
  final String uid;
  final String displayName;
  final String email;
  final String emailLowercase;
  final String avatarUrl;
  final int currentLevel;
  final String currentClass;
  final int xp;
  final int streakDays;
  final DateTime? updatedAt;

  const PublicProfileModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.emailLowercase,
    this.avatarUrl = '',
    this.currentLevel = 1,
    this.currentClass = 'Novice',
    this.xp = 0,
    this.streakDays = 0,
    this.updatedAt,
  });

  factory PublicProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final email = data['email'] as String? ?? '';
    return PublicProfileModel(
      uid: data['uid'] as String? ?? doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: email,
      emailLowercase:
          data['emailLowercase'] as String? ?? email.trim().toLowerCase(),
      avatarUrl: data['avatarUrl'] as String? ?? '',
      currentLevel: (data['currentLevel'] as num?)?.toInt() ?? 1,
      currentClass: data['currentClass'] as String? ?? 'Novice',
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'emailLowercase': emailLowercase,
    'avatarUrl': avatarUrl,
    'currentLevel': currentLevel,
    'currentClass': currentClass,
    'xp': xp,
    'streakDays': streakDays,
    'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
  };
}
