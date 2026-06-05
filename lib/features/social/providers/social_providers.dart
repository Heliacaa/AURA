import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/social_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/challenge.dart';
import '../models/activity.dart';
import 'friends_provider.dart';

final socialServiceProvider = Provider<SocialService>((ref) {
  return SocialService();
});

final currentUserIdProvider = Provider<String?>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  return authUser?.uid;
});

final challengesProvider = StreamProvider<List<Challenge>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return const Stream.empty();
  return ref.watch(socialServiceProvider).getChallengesStream();
});

final activitiesProvider = StreamProvider<List<ActivityFeedItem>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();
  final friendUids = (ref.watch(friendsProvider).valueOrNull ?? const [])
      .map((friendship) => friendship.otherUid(user.uid))
      .where((uid) => uid.isNotEmpty)
      .toList();
  return ref
      .watch(socialServiceProvider)
      .getActivitiesStream(user.uid, friendUids);
});

final unreadActivityCountProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return 0;

  return countUnreadActivities(
    activities: ref.watch(activitiesProvider).valueOrNull ?? const [],
    currentUid: user.uid,
    lastReadAt: user.lastSocialFeedReadAt,
  );
});

int countUnreadActivities({
  required List<ActivityFeedItem> activities,
  required String currentUid,
  DateTime? lastReadAt,
}) {
  return activities.where((activity) {
    if (activity.actorUid == currentUid) return false;
    return lastReadAt == null || activity.createdAt.isAfter(lastReadAt);
  }).length;
}
