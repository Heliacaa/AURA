import 'package:cloud_firestore/cloud_firestore.dart';

class FriendshipModel {
  final String id;
  final List<String> participantUids;
  final String requesterUid;
  final String recipientUid;
  final String status; // pending, accepted
  final DateTime createdAt;
  final DateTime updatedAt;
  final FriendSnapshot requester;
  final FriendSnapshot recipient;

  const FriendshipModel({
    required this.id,
    required this.participantUids,
    required this.requesterUid,
    required this.recipientUid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.requester,
    required this.recipient,
  });

  factory FriendshipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendshipModel(
      id: doc.id,
      participantUids: List<String>.from(data['participantUids'] ?? const []),
      requesterUid: data['requesterUid'] as String? ?? '',
      recipientUid: data['recipientUid'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      requester: FriendSnapshot.fromMap(
        data['requester'] as Map<String, dynamic>? ?? const {},
        fallbackUid: data['requesterUid'] as String? ?? '',
      ),
      recipient: FriendSnapshot.fromMap(
        data['recipient'] as Map<String, dynamic>? ?? const {},
        fallbackUid: data['recipientUid'] as String? ?? '',
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'participantUids': participantUids,
    'requesterUid': requesterUid,
    'recipientUid': recipientUid,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'requester': requester.toMap(),
    'recipient': recipient.toMap(),
  };

  FriendshipModel copyWith({String? status, DateTime? updatedAt}) {
    return FriendshipModel(
      id: id,
      participantUids: participantUids,
      requesterUid: requesterUid,
      recipientUid: recipientUid,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      requester: requester,
      recipient: recipient,
    );
  }

  FriendSnapshot otherUser(String currentUid) {
    return requesterUid == currentUid ? recipient : requester;
  }

  String otherUid(String currentUid) {
    return requesterUid == currentUid ? recipientUid : requesterUid;
  }

  bool isIncomingFor(String currentUid) {
    return isPending && recipientUid == currentUid;
  }

  bool isOutgoingFor(String currentUid) {
    return isPending && requesterUid == currentUid;
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
}

class FriendSnapshot {
  final String uid;
  final String displayName;
  final String email;
  final String avatarUrl;

  const FriendSnapshot({
    required this.uid,
    required this.displayName,
    required this.email,
    this.avatarUrl = '',
  });

  factory FriendSnapshot.fromMap(
    Map<String, dynamic> map, {
    required String fallbackUid,
  }) {
    return FriendSnapshot(
      uid: map['uid'] as String? ?? fallbackUid,
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'avatarUrl': avatarUrl,
  };
}
