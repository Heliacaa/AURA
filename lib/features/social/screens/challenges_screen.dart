import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/challenge_card.dart';
import '../providers/social_providers.dart';
import '../../../../core/theme/app_theme.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sadece development için seed datayı tetikler, asıl prod'da backend halleder.
    ref.read(loadMockSocialDataProvider);

    final challengesAsyncValue = ref.watch(challengesProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return challengesAsyncValue.when(
      data: (challenges) {
        if (challenges.isEmpty) {
          return const Center(
            child: Text(
              "Henüz aktif bir meydan okuma yok.",
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            final isParticipating = currentUserId != null && challenge.participants.contains(currentUserId);

            return ChallengeCard(
              title: challenge.title,
              description: challenge.description,
              progress: challenge.progress,
              currentAmount: challenge.currentAmount,
              targetAmount: challenge.targetAmount,
              unit: challenge.unit,
              isParticipating: isParticipating,
              onJoinPressed: () {
                ref.read(socialServiceProvider).toggleChallengeParticipation(challenge.id);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent)),
      error: (error, stack) => Center(
        child: Text("Hata oluştu: ${error.toString()}", style: const TextStyle(color: Colors.redAccent)),
      ),
    );
  }
}
