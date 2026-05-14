import 'user_model.dart';

enum ProfileRelationshipStatus {
  self,
  none,
  outgoingPending,
  incomingPending,
  accepted,
}

class PublicProfileModel {
  final String uid;
  final String displayName;
  final String email;
  final String avatarUrl;
  final int currentLevel;
  final String currentClass;
  final int xp;
  final int streakDays;
  final int weeklyXp;
  final String weeklyXpWeek;
  final ProfileRelationshipStatus relationshipStatus;
  final String? friendshipId;
  final int? age;
  final DailyGoals? dailyGoals;
  final String? socialEnergyLevel;

  const PublicProfileModel({
    required this.uid,
    required this.displayName,
    this.email = '',
    this.avatarUrl = '',
    required this.currentLevel,
    required this.currentClass,
    required this.xp,
    required this.streakDays,
    required this.weeklyXp,
    required this.weeklyXpWeek,
    required this.relationshipStatus,
    this.friendshipId,
    this.age,
    this.dailyGoals,
    this.socialEnergyLevel,
  });

  factory PublicProfileModel.fromMap(Map<String, dynamic> map) {
    return PublicProfileModel(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      currentLevel: (map['currentLevel'] as num?)?.toInt() ?? 1,
      currentClass: map['currentClass'] as String? ?? 'Novice',
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
      weeklyXp: (map['weeklyXp'] as num?)?.toInt() ?? 0,
      weeklyXpWeek: map['weeklyXpWeek'] as String? ?? '',
      relationshipStatus: _relationshipStatusFromString(
        map['relationshipStatus'] as String? ?? 'none',
      ),
      friendshipId: map['friendshipId'] as String?,
      age: (map['age'] as num?)?.toInt(),
      dailyGoals: map['dailyGoals'] is Map
          ? DailyGoals.fromMap(Map<String, dynamic>.from(map['dailyGoals']))
          : null,
      socialEnergyLevel: map['socialEnergyLevel'] as String?,
    );
  }

  bool get isSelf => relationshipStatus == ProfileRelationshipStatus.self;
  bool get isFriend => relationshipStatus == ProfileRelationshipStatus.accepted;
  bool get isIncomingRequest =>
      relationshipStatus == ProfileRelationshipStatus.incomingPending;
  bool get isOutgoingRequest =>
      relationshipStatus == ProfileRelationshipStatus.outgoingPending;

  String get classIcon => UserModel(
    uid: uid,
    displayName: displayName,
    email: email,
    createdAt: DateTime.now(),
    currentClass: currentClass,
    lastActiveDate: DateTime.now(),
  ).classIcon;
}

ProfileRelationshipStatus _relationshipStatusFromString(String value) {
  switch (value) {
    case 'self':
      return ProfileRelationshipStatus.self;
    case 'outgoingPending':
      return ProfileRelationshipStatus.outgoingPending;
    case 'incomingPending':
      return ProfileRelationshipStatus.incomingPending;
    case 'accepted':
      return ProfileRelationshipStatus.accepted;
    case 'none':
    default:
      return ProfileRelationshipStatus.none;
  }
}
