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

    // timeago türkçe vb ayarlanabilir. Basitçe:
    timeago.setLocaleMessages('tr', timeago.TrMessages());

    return activitiesAsyncValue.when(
      data: (activities) {
        if (activities.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Henüz bir aktivite yok.\n3 günlük seri, seviye atlama veya yeni başarı açınca burada görünür.',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];

            return ActivityFeedCard(
              userName: activity.actorDisplayName,
              userAvatarUrl: activity.actorAvatarUrl,
              actionTitle: activity.title,
              actionDescription: activity.description,
              timeAgo: timeago.format(activity.createdAt, locale: 'tr'),
              isSpecialAchievement: activity.isSpecialAchievement,
              onUserTap: activity.actorUid.isEmpty
                  ? null
                  : () => context.push('/public-profile/${activity.actorUid}'),
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
