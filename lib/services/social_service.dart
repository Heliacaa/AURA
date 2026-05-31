import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../features/social/models/challenge.dart';
import '../features/social/models/activity.dart';

class SocialService {
  SocialService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Stream<List<Challenge>> getChallengesStream() {
    return _db
        .collection('social_challenges')
        .orderBy('endDate', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Challenge.fromFirestore(doc)).toList(),
        );
  }

  Future<void> toggleChallengeParticipation(String challengeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final docRef = _db.collection('social_challenges').doc(challengeId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      List<dynamic> participants = snapshot.data()?['participants'] ?? [];

      if (participants.contains(uid)) {
        transaction.update(docRef, {
          'participants': FieldValue.arrayRemove([uid]),
        });
      } else {
        transaction.update(docRef, {
          'participants': FieldValue.arrayUnion([uid]),
        });
      }
    });
  }

  // Meydan Okuma İlerlemesini Artırma (Adım ekledikçe, su içtikçe)
  Future<void> incrementChallengeProgress(String type, int amountToAdd) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null || amountToAdd <= 0) {
        debugPrint('⚠️ Geçersiz işlem: uid=$uid, amountToAdd=$amountToAdd');
        return;
      }

      debugPrint(
        '⏳ incrementChallengeProgress tetiklendi. type: $type, amount: $amountToAdd, uid: $uid',
      );

      // Kullanıcının katıldığı challenge'ları getiriyoruz
      final query = await _db
          .collection('social_challenges')
          .where('participants', arrayContains: uid)
          .get();

      debugPrint(
        'Bulunan challenge sayısı (katılımcı olduğun): ${query.docs.length}',
      );

      int matchCount = 0;

      for (var doc in query.docs) {
        final data = doc.data();
        final String? docType = data['type'] as String?;
        final String unit = (data['unit'] as String?)?.toLowerCase() ?? '';
        final String title = data['title'] as String? ?? 'İsimsiz';

        bool isMatch = docType == type;

        if (docType == null || docType == 'unknown') {
          if (type == 'water' &&
              (unit.contains('bardak') ||
                  unit.contains('su') ||
                  title.toLowerCase().contains('su'))) {
            isMatch = true;
          } else if (type == 'steps' &&
              (unit.contains('adım') ||
                  unit.contains('adim') ||
                  title.toLowerCase().contains('adım'))) {
            isMatch = true;
          }
        }

        if (isMatch) {
          debugPrint('🎯 Eşleşen Challenge bulundu: $title. Güncelleniyor...');
          await doc.reference.update({
            'currentAmount': FieldValue.increment(amountToAdd),
            if (docType == null || docType == 'unknown') 'type': type,
          });
          matchCount++;
          debugPrint('✅ Topluluk Hedefi güncellendi: $title (+$amountToAdd)');
        } else {
          debugPrint(
            '⏭️ Eşleşmedi: $title. Beklenen: $type, Gelen type: $docType, Unit: $unit',
          );
        }
      }

      if (matchCount == 0) {
        debugPrint(
          '⚠️ Bu işlem tipinde ($type) eşleşen ve katılımcısı olduğunuz challenge bulunamadı. Lütfen önce Topluluk sekmesinden meydan okumaya KATIL (Ayrıl yazıyorsa katılmışsındır) tuşuna basıp basmadığını kontrol et.',
        );
      }
    } catch (e) {
      debugPrint('❌ Meydan okuma skorunu güncellerken hata oluştu: $e');
    }
  }

  Stream<List<ActivityFeedItem>> getActivitiesStream() {
    return _db
        .collection('social_activities')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActivityFeedItem.fromFirestore(doc))
              .where((activity) => !activity.isLegacyMock)
              .toList(),
        );
  }

  Future<void> toggleLikeActivity(String activityId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final docRef = _db.collection('social_activities').doc(activityId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      List<dynamic> likes = snapshot.data()?['likes'] ?? [];

      if (likes.contains(uid)) {
        transaction.update(docRef, {
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        transaction.update(docRef, {
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
    });
  }

  Future<void> ensureDefaultSocialData() async {
    final challengesRef = _db.collection('social_challenges');
    final activitiesRef = _db.collection('social_activities');

    await _removeLegacyMockActivities(activitiesRef);

    final snap = await challengesRef.limit(1).get();
    if (snap.docs.isEmpty) {
      await challengesRef.add({
        'title': "Adım Topluluğu: 1 Milyon!",
        'description':
            "Topluluk olarak bu hafta toplam 1 milyon adım atıyoruz. Sen de katıl!",
        'type': "steps",
        'currentAmount': 650000,
        'targetAmount': 1000000,
        'unit': "Adım",
        'participants': [],
        'createdAt': FieldValue.serverTimestamp(),
        'endDate': FieldValue.serverTimestamp(),
      });
      await challengesRef.add({
        'title': "Susuz Kalma!",
        'description':
            "Bugün toplam 5.000 bardak su içme hedefine ulaşırsak sürpriz sandık açılacak.",
        'type': "water",
        'currentAmount': 1500,
        'targetAmount': 5000,
        'unit': "Bardak",
        'participants': [],
        'createdAt': FieldValue.serverTimestamp(),
        'endDate': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> publishAchievementActivity({
    required String activityId,
    required String uid,
    required String achievementTitle,
    required String achievementDescription,
    required String achievementIcon,
  }) async {
    final profile = await _userSnapshot(uid);
    await _db.collection('social_activities').doc(activityId).set({
      'userId': uid,
      'userName': profile['displayName'] ?? 'AURA User',
      'userAvatarUrl': profile['avatarUrl'] ?? '',
      'actionTitle': '$achievementIcon $achievementTitle Rozeti',
      'actionDescription': achievementDescription,
      'timestamp': FieldValue.serverTimestamp(),
      'isSpecialAchievement': true,
      'likes': [],
    });
  }

  Future<Map<String, dynamic>> _userSnapshot(String uid) async {
    try {
      final publicDoc = await _db.collection('publicProfiles').doc(uid).get();
      if (publicDoc.exists) {
        final data = publicDoc.data() ?? {};
        return {
          'displayName': data['displayName'] ?? '',
          'avatarUrl': data['avatarUrl'] ?? '',
        };
      }

      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        return {
          'displayName': data['displayName'] ?? '',
          'avatarUrl': data['avatarUrl'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('Aktivite profili okunamadı: $e');
    }

    final authUser = _auth.currentUser;
    return {
      'displayName': authUser?.displayName ?? 'AURA User',
      'avatarUrl': authUser?.photoURL ?? '',
    };
  }

  Future<void> _removeLegacyMockActivities(
    CollectionReference activitiesRef,
  ) async {
    try {
      final snap = await activitiesRef
          .where('userId', isEqualTo: 'mock_user_1')
          .limit(25)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Eski mock aktiviteler temizlenemedi: $e');
    }
  }
}
