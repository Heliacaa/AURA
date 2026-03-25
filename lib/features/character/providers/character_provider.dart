import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/achievement_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/firestore_service.dart';

/// Achievements stream
final achievementsProvider = StreamProvider<List<AchievementModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();
  return FirestoreService.instance.achievementsStream(user.uid);
});
