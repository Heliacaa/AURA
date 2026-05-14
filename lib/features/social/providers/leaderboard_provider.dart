import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import 'friends_provider.dart';

/// Leaderboard sort mode
enum LeaderboardSort { weeklyXp, streak, score }

/// Leaderboard surface mode
enum LeaderboardMode { weeklyLeague, friends }

final leaderboardModeProvider = StateProvider<LeaderboardMode>(
  (ref) => LeaderboardMode.weeklyLeague,
);

final leaderboardSortProvider = StateProvider<LeaderboardSort>(
  (ref) => LeaderboardSort.weeklyXp,
);

/// Public weekly league entries for opted-in users.
final weeklyLeaderboardProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return FirestoreService.instance.weeklyLeaderboardStream();
});

/// Leaderboard data: list of friend stats
final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final friends = ref.watch(friendsProvider).valueOrNull ?? [];
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  final sort = ref.watch(leaderboardSortProvider);

  final List<Map<String, dynamic>> entries = [];

  // Add current user
  if (currentUser != null) {
    entries.add({
      'uid': currentUser.uid,
      'displayName': currentUser.displayName,
      'currentLevel': currentUser.currentLevel,
      'xp': currentUser.xp,
      'streakDays': currentUser.streakDays,
      'currentClass': currentUser.currentClass,
      'isMe': true,
    });
  }

  // Add friends
  for (final friend in friends) {
    if (currentUser == null) continue;
    final friendUid = friend.otherUid(currentUser.uid);
    final stats = await FirestoreService.instance.getUserPublicStats(friendUid);
    if (stats != null) {
      entries.add({...stats, 'uid': friendUid, 'isMe': false});
    }
  }

  // Sort based on selected mode
  switch (sort) {
    case LeaderboardSort.weeklyXp:
      entries.sort(
        (a, b) => ((b['xp'] as num?) ?? 0).compareTo((a['xp'] as num?) ?? 0),
      );
      break;
    case LeaderboardSort.streak:
      entries.sort(
        (a, b) => ((b['streakDays'] as num?) ?? 0).compareTo(
          (a['streakDays'] as num?) ?? 0,
        ),
      );
      break;
    case LeaderboardSort.score:
      entries.sort(
        (a, b) => ((b['currentLevel'] as num?) ?? 0).compareTo(
          (a['currentLevel'] as num?) ?? 0,
        ),
      );
      break;
  }

  return entries;
});
