import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/friendship_model.dart';
import '../../../shared/models/public_profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/friend_service.dart';

final friendServiceProvider = Provider<FriendService>((ref) {
  return FriendService();
});

final publicProfileProvider = FutureProvider.family<PublicProfileModel, String>(
  (ref, uid) async {
    return ref.read(friendServiceProvider).getPublicProfile(uid);
  },
);

final friendshipsProvider = StreamProvider<List<FriendshipModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();
  return FirestoreService.instance.friendshipsStream(user.uid);
});

/// Accepted friends derived from the single live friendships stream.
final friendsProvider = Provider<AsyncValue<List<FriendshipModel>>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const AsyncValue.data([]);

  return ref
      .watch(friendshipsProvider)
      .whenData((items) => items.where((item) => item.isAccepted).toList());
});

/// Pending friend requests received by the current user.
final friendRequestsProvider = Provider<AsyncValue<List<FriendshipModel>>>((
  ref,
) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const AsyncValue.data([]);

  return ref
      .watch(friendshipsProvider)
      .whenData(
        (items) =>
            items.where((item) => item.isIncomingFor(authUser.uid)).toList(),
      );
});

final sentFriendRequestsProvider = Provider<AsyncValue<List<FriendshipModel>>>((
  ref,
) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const AsyncValue.data([]);

  return ref
      .watch(friendshipsProvider)
      .whenData(
        (items) =>
            items.where((item) => item.isOutgoingFor(authUser.uid)).toList(),
      );
});
