import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/social_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/challenge.dart';
import '../models/activity.dart';

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
  if (authState.valueOrNull == null) return const Stream.empty();
  return ref.watch(socialServiceProvider).getActivitiesStream();
});

final ensureDefaultSocialDataProvider = FutureProvider<void>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return;
  final service = ref.read(socialServiceProvider);
  await service.ensureDefaultSocialData();
});
