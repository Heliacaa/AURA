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
  return ref.watch(socialServiceProvider).getChallengesStream();
});

final activitiesProvider = StreamProvider<List<ActivityFeedItem>>((ref) {
  return ref.watch(socialServiceProvider).getActivitiesStream();
});

// A utility provider to load initial mock data if necessary during development
final loadMockSocialDataProvider = FutureProvider<void>((ref) async {
  final service = ref.read(socialServiceProvider);
  await service.generateMockData();
});
