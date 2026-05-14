import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/date_utils.dart';
import '../shared/models/public_profile_model.dart';

class FriendFunctionsService {
  FriendFunctionsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<PublicProfileModel?> searchUserByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final searchDoc = await _getDoc(
      _db.collection('userSearch').doc(normalized),
    );
    if (searchDoc != null && searchDoc.exists) {
      final data = searchDoc.data() as Map<String, dynamic>? ?? {};
      final uid = data['uid'] as String? ?? '';
      if (uid.isNotEmpty) return getPublicProfile(uid);
    }

    final publicByEmail = await _queryFirst(
      _db
          .collection('publicProfiles')
          .where('emailLower', isEqualTo: normalized)
          .limit(1),
    );
    if (publicByEmail != null) {
      return _profileFromPublicDoc(publicByEmail, includeEmail: true);
    }

    final userByEmailLower = await _queryFirst(
      _db
          .collection('users')
          .where('emailLower', isEqualTo: normalized)
          .limit(1),
    );
    if (userByEmailLower != null) {
      return _profileFromUserDoc(userByEmailLower, includeEmail: true);
    }

    final userByEmail = await _queryFirst(
      _db.collection('users').where('email', isEqualTo: email.trim()).limit(1),
    );
    if (userByEmail != null) {
      return _profileFromUserDoc(userByEmail, includeEmail: true);
    }

    return null;
  }

  Future<PublicProfileModel> getPublicProfile(String uid) async {
    final publicDoc = await _getDoc(_db.collection('publicProfiles').doc(uid));
    if (publicDoc != null && publicDoc.exists) {
      return _profileFromPublicDoc(publicDoc);
    }

    final userDoc = await _getDoc(_db.collection('users').doc(uid));
    if (userDoc != null && userDoc.exists) {
      return _profileFromUserDoc(userDoc);
    }

    final leaderboardDoc = await _getDoc(
      _db
          .collection('leaderboards')
          .doc(AppDateUtils.weekKey())
          .collection('entries')
          .doc(uid),
    );
    if (leaderboardDoc != null && leaderboardDoc.exists) {
      final data = leaderboardDoc.data() as Map<String, dynamic>? ?? {};
      return PublicProfileModel.fromMap({
        'uid': uid,
        'displayName': data['displayName'] ?? '',
        'avatarUrl': data['avatarUrl'] ?? '',
        'currentLevel': data['currentLevel'] ?? 1,
        'currentClass': data['currentClass'] ?? 'Novice',
        'xp': data['xp'] ?? 0,
        'streakDays': data['streakDays'] ?? 0,
        'weeklyXp': data['weeklyXp'] ?? 0,
        'weeklyXpWeek': data['weekKey'] ?? AppDateUtils.weekKey(),
        'relationshipStatus': await _relationshipStatus(uid),
      });
    }

    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'not-found',
      message: 'Profil bulunamadı',
    );
  }

  Future<void> sendFriendRequest(String toUid) async {
    final fromUid = _currentUid();
    if (fromUid == toUid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'failed-precondition',
        message: 'Kendinizi ekleyemezsiniz.',
      );
    }

    final friendshipRef = _friendshipRef(fromUid, toUid);
    final existing = await friendshipRef.get();
    if (existing.exists) {
      final status =
          (existing.data() as Map<String, dynamic>? ?? {})['status'] as String?;
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: status == 'accepted'
            ? 'Zaten arkadaşsınız.'
            : 'Bu kullanıcıyla bekleyen bir istek var.',
      );
    }

    final requester = await _snapshotForUid(fromUid);
    final recipient = await _snapshotForUid(toUid);
    await friendshipRef.set({
      'participantUids': [fromUid, toUid],
      'requesterUid': fromUid,
      'recipientUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'requester': requester,
      'recipient': recipient,
    });
  }

  Future<void> acceptFriendRequest(String otherUid) async {
    await _friendshipRef(_currentUid(), otherUid).update({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> declineFriendRequest(String otherUid) async {
    await _friendshipRef(_currentUid(), otherUid).delete();
  }

  Future<void> removeFriend(String otherUid) async {
    await _friendshipRef(_currentUid(), otherUid).delete();
  }

  Future<PublicProfileModel> _profileFromPublicDoc(
    DocumentSnapshot doc, {
    bool includeEmail = false,
  }) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final profile = <String, dynamic>{
      ...data,
      'uid': data['uid'] ?? doc.id,
      'relationshipStatus': await _relationshipStatus(doc.id),
    };
    if (!includeEmail && profile['relationshipStatus'] != 'self') {
      profile.remove('email');
    }
    await _addFriendVisibleFields(profile);
    return PublicProfileModel.fromMap(profile);
  }

  Future<PublicProfileModel> _profileFromUserDoc(
    DocumentSnapshot doc, {
    bool includeEmail = false,
  }) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final status = await _relationshipStatus(doc.id);
    final profile = <String, dynamic>{
      'uid': doc.id,
      'displayName': data['displayName'] ?? '',
      'email': includeEmail || status == 'self' ? data['email'] ?? '' : '',
      'avatarUrl': data['avatarUrl'] ?? '',
      'currentLevel': data['currentLevel'] ?? 1,
      'currentClass': data['currentClass'] ?? 'Novice',
      'xp': data['xp'] ?? 0,
      'streakDays': data['streakDays'] ?? 0,
      'weeklyXp': data['weeklyXp'] ?? 0,
      'weeklyXpWeek': data['weeklyXpWeek'] ?? '',
      'relationshipStatus': status,
    };
    if (status == 'self' || status == 'accepted') {
      profile['age'] = data['age'];
      profile['dailyGoals'] = data['dailyGoals'];
      profile['socialEnergyLevel'] = data['socialEnergyLevel'];
    }
    await _addFriendVisibleFields(profile);
    return PublicProfileModel.fromMap(profile);
  }

  Future<void> _addFriendVisibleFields(Map<String, dynamic> profile) async {
    final status = profile['relationshipStatus'] as String? ?? 'none';
    if (status != 'self' && status != 'accepted') return;

    final friendDoc = await _getDoc(
      _db.collection('friendProfiles').doc(profile['uid'] as String),
    );
    if (friendDoc == null || !friendDoc.exists) return;
    final data = friendDoc.data() as Map<String, dynamic>? ?? {};
    profile['age'] ??= data['age'];
    profile['dailyGoals'] ??= data['dailyGoals'];
    profile['socialEnergyLevel'] ??= data['socialEnergyLevel'];
  }

  Future<String> _relationshipStatus(String targetUid) async {
    final uid = _currentUid();
    if (uid == targetUid) return 'self';

    final doc = await _getDoc(_friendshipRef(uid, targetUid));
    if (doc == null || !doc.exists) return 'none';
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final status = data['status'] as String? ?? 'none';
    if (status == 'accepted') return 'accepted';
    if (status == 'pending' && data['requesterUid'] == uid) {
      return 'outgoingPending';
    }
    if (status == 'pending' && data['recipientUid'] == uid) {
      return 'incomingPending';
    }
    return 'none';
  }

  Future<Map<String, dynamic>> _snapshotForUid(String uid) async {
    final publicDoc = await _getDoc(_db.collection('publicProfiles').doc(uid));
    if (publicDoc != null && publicDoc.exists) {
      final data = publicDoc.data() as Map<String, dynamic>? ?? {};
      return {
        'uid': uid,
        'displayName': data['displayName'] ?? '',
        'email': data['email'] ?? '',
        'avatarUrl': data['avatarUrl'] ?? '',
      };
    }

    final userDoc = await _getDoc(_db.collection('users').doc(uid));
    if (userDoc != null && userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      return {
        'uid': uid,
        'displayName': data['displayName'] ?? '',
        'email': data['email'] ?? '',
        'avatarUrl': data['avatarUrl'] ?? '',
      };
    }

    final authUser = _auth.currentUser;
    if (authUser != null && authUser.uid == uid) {
      return {
        'uid': uid,
        'displayName': authUser.displayName ?? '',
        'email': authUser.email ?? '',
        'avatarUrl': authUser.photoURL ?? '',
      };
    }

    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'not-found',
      message: 'Kullanıcı bulunamadı.',
    );
  }

  DocumentReference _friendshipRef(String uidA, String uidB) {
    return _db.collection('friendships').doc(_friendshipId(uidA, uidB));
  }

  String _friendshipId(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  String _currentUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'unauthenticated',
        message: 'Giriş yapılmamış.',
      );
    }
    return uid;
  }

  Future<DocumentSnapshot?> _getDoc(DocumentReference ref) async {
    try {
      return await ref.get();
    } on FirebaseException {
      return null;
    }
  }

  Future<QueryDocumentSnapshot?> _queryFirst(Query query) async {
    try {
      final snap = await query.get();
      return snap.docs.isEmpty ? null : snap.docs.first;
    } on FirebaseException {
      return null;
    }
  }
}
