import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../social/providers/social_providers.dart';
import '../../social/widgets/challenge_card.dart';

class HomeActiveChallenges extends ConsumerWidget {
  const HomeActiveChallenges({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    if (currentUserId == null) return const SizedBox.shrink();

    return challengesAsync.when(
      data: (challenges) {
        // Sadece kullanıcının katıldığı(participant olduğu) meydan okumaları filtrele
        final activeChallenges = challenges
            .where((c) => c.participants.contains(currentUserId))
            .toList();

        if (activeChallenges.isEmpty) {
          return const SizedBox.shrink(); // Katıldığınız hedef yoksa ekranda yer kaplamasın.
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktif Topluluk Hedefleri',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ...activeChallenges.map(
              (challenge) => ChallengeCard(
                title: challenge.title,
                // description: challenge.description, (Topluluk hedeflerinde ana ekranda kısaltabilir veya kendi açıklamanızı basabilirsiniz)
                description: challenge.description,
                progress: challenge.progress,
                currentAmount: challenge.currentAmount,
                targetAmount: challenge.targetAmount,
                unit: challenge.unit,
                isParticipating: true,
                onJoinPressed: () {
                  // Tıklandığında ayrılmasını sağlar. (Ayrılınca bu widget ekrandan yeniden build ile kaybolur)
                  ref
                      .read(socialServiceProvider)
                      .toggleChallengeParticipation(challenge.id);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
