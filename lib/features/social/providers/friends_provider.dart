import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/friendship_model.dart';
import '../../../shared/models/public_profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/friend_functions_service.dart';

final friendFunctionsServiceProvider = Provider<FriendFunctionsService>((ref) {
  return FriendFunctionsService();
});

final publicProfileProvider = FutureProvider.family<PublicProfileModel, String>(
  (ref, uid) async {
    return ref.read(friendFunctionsServiceProvider).getPublicProfile(uid);
  },
);

final friendshipsProvider = StreamProvider<List<FriendshipModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();
  return FirestoreService.instance.friendshipsStream(user.uid);
});

/// Stream of accepted friends
final friendsProvider = StreamProvider<List<FriendshipModel>>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  final items = ref.watch(friendshipsProvider).valueOrNull ?? [];
  if (authState == null) return const Stream.empty();
  return Stream.value(items.where((item) => item.isAccepted).toList());
});

/// Stream of pending friend requests
final friendRequestsProvider = StreamProvider<List<FriendshipModel>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final items = ref.watch(friendshipsProvider).valueOrNull ?? [];
  if (authUser == null) return const Stream.empty();
  return Stream.value(
    items.where((item) => item.isIncomingFor(authUser.uid)).toList(),
  );
});

final sentFriendRequestsProvider = StreamProvider<List<FriendshipModel>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final items = ref.watch(friendshipsProvider).valueOrNull ?? [];
  if (authUser == null) return const Stream.empty();
  return Stream.value(
    items.where((item) => item.isOutgoingFor(authUser.uid)).toList(),
  );
});
