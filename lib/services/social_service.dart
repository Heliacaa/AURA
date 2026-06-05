import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/date_utils.dart';
import '../features/social/models/activity.dart';
import '../features/social/models/challenge.dart';

class SocialService {
  SocialService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Stream<List<Challenge>> getChallengesStream() {
    late final StreamController<List<Challenge>> controller;
    StreamSubscription? challengeSubscription;
    final contributionSubscriptions = <String, StreamSubscription>{};
    final challenges = <String, Challenge>{};
    final contributionTotals = <String, int>{};
    final readyChallengeIds = <String>{};

    void emit() {
      if (!readyChallengeIds.containsAll(challenges.keys)) return;
      final items =
          challenges.values
              .map(
                (challenge) => challenge.copyWith(
                  currentAmount: contributionTotals[challenge.id] ?? 0,
                ),
              )
              .toList()
            ..sort((a, b) => a.endDate.compareTo(b.endDate));
      controller.add(items);
    }

    void start() {
      challengeSubscription = _db
          .collection('social_challenges')
          .orderBy('endDate', descending: false)
          .snapshots()
          .listen((snapshot) {
            final activeIds = snapshot.docs.map((doc) => doc.id).toSet();

            for (final removedId
                in contributionSubscriptions.keys
                    .where((id) => !activeIds.contains(id))
                    .toList()) {
              final removed = contributionSubscriptions.remove(removedId);
              if (removed != null) unawaited(removed.cancel());
              challenges.remove(removedId);
              contributionTotals.remove(removedId);
              readyChallengeIds.remove(removedId);
            }

            for (final doc in snapshot.docs) {
              challenges[doc.id] = Challenge.fromFirestore(doc);
              if (contributionSubscriptions.containsKey(doc.id)) continue;

              contributionSubscriptions[doc.id] = doc.reference
                  .collection('progressContributions')
                  .snapshots()
                  .listen((contributions) {
                    contributionTotals[doc.id] = contributions.docs.fold(
                      0,
                      (total, contribution) =>
                          total +
                          ((contribution.data()['creditedAmount'] as num?)
                                  ?.toInt() ??
                              0),
                    );
                    readyChallengeIds.add(doc.id);
                    emit();
                  }, onError: controller.addError);
            }

            if (challenges.isEmpty) controller.add(const []);
            emit();
          }, onError: controller.addError);
    }

    Future<void> cancel() async {
      await challengeSubscription?.cancel();
      for (final subscription in contributionSubscriptions.values) {
        await subscription.cancel();
      }
    }

    controller = StreamController<List<Challenge>>(
      onListen: start,
      onCancel: cancel,
    );
    return controller.stream;
  }

  Future<void> toggleChallengeParticipation(String challengeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final challengeRef = _db.collection('social_challenges').doc(challengeId);
    var joined = false;
    var challengeType = '';

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(challengeRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? const <String, dynamic>{};
      final participants = List<String>.from(data['participants'] ?? const []);
      challengeType = data['type'] as String? ?? '';

      if (participants.contains(uid)) {
        transaction.update(challengeRef, {
          'participants': FieldValue.arrayRemove([uid]),
        });
      } else {
        joined = true;
        transaction.update(challengeRef, {
          'participants': FieldValue.arrayUnion([uid]),
        });
      }
    });

    if (joined) {
      try {
        await _syncJoinedChallengeContribution(
          uid: uid,
          challengeId: challengeId,
          challengeType: challengeType,
        );
      } catch (_) {
        // Joining remains successful if the optional contribution sync fails.
      }
    }
  }

  Stream<List<ActivityFeedItem>> getActivitiesStream(
    String uid,
    Iterable<String> friendUids,
  ) {
    late final StreamController<List<ActivityFeedItem>> controller;
    final subscriptions = <StreamSubscription>[];
    final sourceItems = <int, List<ActivityFeedItem>>{};
    final readySources = <int>{};
    var likedActivityIds = <String>{};
    var likesReady = false;

    final actorUids = <String>{uid, ...friendUids}.toList();
    final queries = <Query<Map<String, dynamic>>>[
      _db
          .collection('social_activities')
          .where('visibility', isEqualTo: 'global')
          .orderBy('createdAt', descending: true)
          .limit(50),
      ...actorUids.map(
        (actorUid) => _db
            .collection('social_activities')
            .where('actorUid', isEqualTo: actorUid)
            .orderBy('createdAt', descending: true)
            .limit(50),
      ),
    ];

    void emit() {
      if (!likesReady || readySources.length != queries.length) return;

      final byId = <String, ActivityFeedItem>{};
      for (final items in sourceItems.values) {
        for (final item in items) {
          byId[item.id] = item.copyWith(
            isLikedByCurrentUser: likedActivityIds.contains(item.id),
          );
        }
      }

      final activities = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(activities.take(50).toList());
    }

    void markSourceReady(int index, List<ActivityFeedItem> items) {
      if (controller.isClosed) return;
      sourceItems[index] = items;
      readySources.add(index);
      emit();
    }

    void handleSourceError(int index, Object error, StackTrace stackTrace) {
      if (error is FirebaseException && error.code == 'permission-denied') {
        markSourceReady(index, const []);
        return;
      }
      if (!controller.isClosed) controller.addError(error, stackTrace);
    }

    void handleLikesError(Object error, StackTrace stackTrace) {
      if (error is FirebaseException && error.code == 'permission-denied') {
        likedActivityIds = const {};
        likesReady = true;
        emit();
        return;
      }
      if (!controller.isClosed) controller.addError(error, stackTrace);
    }

    void start() {
      for (var index = 0; index < queries.length; index++) {
        subscriptions.add(
          queries[index].snapshots().listen(
            (snapshot) {
              markSourceReady(
                index,
                snapshot.docs.map(ActivityFeedItem.fromFirestore).toList(),
              );
            },
            onError: (Object error, StackTrace stackTrace) {
              handleSourceError(index, error, stackTrace);
            },
          ),
        );
      }

      subscriptions.add(
        _db
            .collection('users')
            .doc(uid)
            .collection('activityLikes')
            .snapshots()
            .listen((snapshot) {
              likedActivityIds = snapshot.docs.map((doc) => doc.id).toSet();
              likesReady = true;
              emit();
            }, onError: handleLikesError),
      );
    }

    Future<void> cancel() async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }

    controller = StreamController<List<ActivityFeedItem>>(
      onListen: start,
      onCancel: cancel,
    );
    return controller.stream;
  }

  Future<void> toggleLikeActivity(String activityId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final likeRef = _db
        .collection('users')
        .doc(uid)
        .collection('activityLikes')
        .doc(activityId);
    final like = await likeRef.get();
    if (like.exists) {
      await likeRef.delete();
    } else {
      await likeRef.set({
        'uid': uid,
        'activityId': activityId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _syncJoinedChallengeContribution({
    required String uid,
    required String challengeId,
    required String challengeType,
  }) async {
    final logId = AppDateUtils.todayKey();
    final log = await _db
        .collection('users')
        .doc(uid)
        .collection('dailyLogs')
        .doc(logId)
        .get();
    if (!log.exists) return;

    final data = log.data() ?? const <String, dynamic>{};
    final observedAmount = challengeType == 'steps'
        ? (data['stepCount'] as num?)?.toInt() ?? 0
        : challengeType == 'water'
        ? (data['waterGlasses'] as num?)?.toInt() ?? 0
        : 0;
    if (observedAmount <= 0) return;

    await _writeContribution(
      uid: uid,
      challengeId: challengeId,
      logId: logId,
      observedAmount: observedAmount,
    );
  }

  Future<void> _writeContribution({
    required String uid,
    required String challengeId,
    required String logId,
    required int observedAmount,
  }) async {
    final contributionRef = _db
        .collection('social_challenges')
        .doc(challengeId)
        .collection('progressContributions')
        .doc('${uid}_$logId');

    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(contributionRef);
      final creditedAmount = existing.exists
          ? ((existing.data()?['creditedAmount'] as num?)?.toInt() ?? 0)
          : 0;
      if (observedAmount <= creditedAmount) return;

      transaction.set(contributionRef, {
        'challengeId': challengeId,
        'userId': uid,
        'logId': logId,
        'creditedAmount': observedAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
