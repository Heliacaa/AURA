import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/activity_feed_card.dart';
import '../providers/social_providers.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsyncValue = ref.watch(activitiesProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    // timeago türkçe vb ayarlanabilir. Basitçe:
    timeago.setLocaleMessages('tr', timeago.TrMessages());

    return activitiesAsyncValue.when(
      data: (activities) {
        if (activities.isEmpty) {
          return const Center(
            child: Text(
              "Henüz bir aktivite yok.",
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            final isLikedByMe =
                currentUserId != null && activity.likes.contains(currentUserId);

            return ActivityFeedCard(
              userName: activity.userName,
              userAvatarUrl: activity.userAvatarUrl,
              actionTitle: activity.actionTitle,
              actionDescription: activity.actionDescription,
              timeAgo: timeago.format(activity.timestamp, locale: 'tr'),
              isSpecialAchievement: activity.isSpecialAchievement,
              isLikedByMe: isLikedByMe,
              onLikePressed: () {
                ref.read(socialServiceProvider).toggleLikeActivity(activity.id);
              },
              onUserTap: activity.userId.isEmpty
                  ? null
                  : () => context.push('/public-profile/${activity.userId}'),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryAccent),
      ),
      error: (error, stack) => Center(
        child: Text(
          "Hata oluştu: ${error.toString()}",
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}
