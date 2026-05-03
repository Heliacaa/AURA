import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(leaderboardModeProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sıralama',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildModeTabs(ref, mode),
          const SizedBox(height: 16),
          if (mode == LeaderboardMode.weeklyLeague) ...[
            _WeeklyLeagueOptInCard(user: user),
            const SizedBox(height: 12),
            Expanded(child: _WeeklyLeagueList(currentUid: user?.uid)),
          ] else ...[
            _buildFriendSortTabs(ref),
            const SizedBox(height: 16),
            Expanded(child: _FriendsLeaderboardList()),
          ],
        ],
      ),
    );
  }

  Widget _buildModeTabs(WidgetRef ref, LeaderboardMode mode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: LeaderboardMode.values.map((item) {
          final isSelected = item == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(leaderboardModeProvider.notifier).state = item,
              child: Container(
                height: 38,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryAccent
                      : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Center(
                  child: Text(
                    _modeLabel(item),
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFriendSortTabs(WidgetRef ref) {
    final sortMode = ref.watch(leaderboardSortProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: LeaderboardSort.values.map((sort) {
          final isSelected = sort == sortMode;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(leaderboardSortProvider.notifier).state = sort,
              child: Container(
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryAccent
                      : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    _sortLabel(sort),
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _modeLabel(LeaderboardMode mode) {
    switch (mode) {
      case LeaderboardMode.weeklyLeague:
        return 'Weekly League';
      case LeaderboardMode.friends:
        return 'Arkadaşlar';
    }
  }

  String _sortLabel(LeaderboardSort sort) {
    switch (sort) {
      case LeaderboardSort.weeklyXp:
        return 'XP';
      case LeaderboardSort.streak:
        return 'Seri';
      case LeaderboardSort.score:
        return 'Seviye';
    }
  }
}

class _WeeklyLeagueOptInCard extends StatelessWidget {
  final UserModel? user;

  const _WeeklyLeagueOptInCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    if (currentUser == null) return const SizedBox.shrink();

    final enabled = currentUser.leaderboardOptIn;
    final title = enabled ? 'Weekly League aktif' : 'Weekly League kapalı';
    final subtitle = enabled
        ? 'Bu hafta ${currentUser.weeklyXp} XP ile sıralamadasın.'
        : 'Haftalık XP sıralamasında görünmek için katıl.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration(
          borderColor: enabled
              ? AppTheme.secondaryAccent
              : AppTheme.warningOrange,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: AppTheme.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppDateUtils.weekKey()} · $subtitle',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: enabled,
              activeThumbColor: AppTheme.secondaryAccent,
              activeTrackColor: AppTheme.secondaryAccent.withAlpha(70),
              onChanged: (value) async {
                try {
                  await FirestoreService.instance.setLeaderboardOptIn(
                    currentUser.uid,
                    value,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Weekly League görünürlüğü açıldı.'
                            : 'Weekly League görünürlüğü kapatıldı.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sıralama güncellenemedi: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyLeagueList extends ConsumerWidget {
  final String? currentUid;

  const _WeeklyLeagueList({required this.currentUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyLeaderboardProvider);

    return weeklyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryAccent),
      ),
      error: (e, _) => Center(
        child: Text(
          'Hata: $e',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Bu haftanın liginde henüz kimse yok. İlk katılan sen olabilirsin.',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final rank = index + 1;
            final isMe = entry['uid'] == currentUid;
            return _LeaderboardEntryTile(
              rank: rank,
              isMe: isMe,
              displayName: entry['displayName'] as String? ?? '',
              subtitle:
                  'Lv.${entry['currentLevel'] ?? 1} ${entry['currentClass'] ?? 'Novice'}',
              value: '${entry['weeklyXp'] ?? 0} XP',
            );
          },
        );
      },
    );
  }
}

class _FriendsLeaderboardList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final sortMode = ref.watch(leaderboardSortProvider);

    return leaderboardAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryAccent),
      ),
      error: (e, _) => Center(
        child: Text(
          'Hata: $e',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Text(
              'Arkadaş ekleyerek sıralamayı görebilirsin!',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final rank = index + 1;
            final isMe = entry['isMe'] as bool? ?? false;
            return _LeaderboardEntryTile(
              rank: rank,
              isMe: isMe,
              displayName: entry['displayName'] as String? ?? '',
              subtitle: 'Lv.${entry['currentLevel']} ${entry['currentClass']}',
              value: _sortValue(entry, sortMode),
            );
          },
        );
      },
    );
  }

  String _sortValue(Map<String, dynamic> entry, LeaderboardSort sort) {
    switch (sort) {
      case LeaderboardSort.weeklyXp:
        return '${entry['xp'] ?? 0} XP';
      case LeaderboardSort.streak:
        return '${entry['streakDays'] ?? 0} 🔥';
      case LeaderboardSort.score:
        return 'Lv.${entry['currentLevel'] ?? 1}';
    }
  }
}

class _LeaderboardEntryTile extends StatelessWidget {
  final int rank;
  final bool isMe;
  final String displayName;
  final String subtitle;
  final String value;

  const _LeaderboardEntryTile({
    required this.rank,
    required this.isMe,
    required this.displayName,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final safeName = displayName.isNotEmpty ? displayName : 'AURA User';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.primaryAccent.withAlpha(30)
            : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: isMe
            ? Border.all(color: AppTheme.primaryAccent, width: 1)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: rank <= 3
                    ? AppTheme.warningOrange
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: isMe
                ? AppTheme.primaryAccent
                : AppTheme.textSecondary,
            radius: 18,
            child: Text(
              safeName[0].toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '$safeName (Sen)' : safeName,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}
