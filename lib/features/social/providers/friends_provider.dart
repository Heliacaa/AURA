import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/friendship_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/firestore_service.dart';

/// Stream of accepted friends
final friendsProvider = StreamProvider<List<FriendshipModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();
  return FirestoreService.instance.friendsStream(user.uid);
});

/// Stream of pending friend requests
final friendRequestsProvider = StreamProvider<List<FriendshipModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();
  return FirestoreService.instance.friendRequestsStream(user.uid);
});
