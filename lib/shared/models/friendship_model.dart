import 'package:cloud_firestore/cloud_firestore.dart';

class FriendshipModel {
  final String friendUid;
  final String friendName;
  final String friendEmail;
  final String status; // pending, accepted
  final String direction; // incoming, outgoing
  final DateTime createdAt;

  const FriendshipModel({
    required this.friendUid,
    required this.friendName,
    required this.friendEmail,
    required this.status,
    this.direction = 'incoming',
    required this.createdAt,
  });

  factory FriendshipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendshipModel(
      friendUid: doc.id,
      friendName: data['friendName'] as String? ?? '',
      friendEmail: data['friendEmail'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      direction: data['direction'] as String? ?? 'incoming',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'friendName': friendName,
    'friendEmail': friendEmail,
    'status': status,
    'direction': direction,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  FriendshipModel copyWith({String? status, String? direction}) {
    return FriendshipModel(
      friendUid: friendUid,
      friendName: friendName,
      friendEmail: friendEmail,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      createdAt: createdAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isIncoming => direction == 'incoming';
  bool get isOutgoing => direction == 'outgoing';
}
