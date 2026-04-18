import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final sortMode = ref.watch(leaderboardSortProvider);

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

          // Sort tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: LeaderboardSort.values.map((sort) {
                final isSelected = sort == sortMode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => ref
                        .read(leaderboardSortProvider.notifier)
                        .state = sort,
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
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
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
          ),
          const SizedBox(height: 16),

          // Leaderboard list
          Expanded(
            child: leaderboardAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primaryAccent),
              ),
              error: (e, _) => Center(
                child: Text('Hata: $e',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary)),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      'Arkadaş ekleyerek sıralamayı görebilirsin!',
                      style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isMe = entry['isMe'] as bool? ?? false;
                    final rank = index + 1;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppTheme.primaryAccent.withAlpha(30)
                            : AppTheme.cardBackground,
                        borderRadius:
                            BorderRadius.circular(AppTheme.cardBorderRadius),
                        border: isMe
                            ? Border.all(
                                color: AppTheme.primaryAccent, width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Rank
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
                          // Avatar
                          CircleAvatar(
                            backgroundColor: isMe
                                ? AppTheme.primaryAccent
                                : AppTheme.textSecondary,
                            radius: 18,
                            child: Text(
                              (entry['displayName'] as String? ?? '?')
                                  .isNotEmpty
                                  ? (entry['displayName'] as String)[0]
                                      .toUpperCase()
                                  : '?',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name and level
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMe
                                      ? '${entry['displayName']} (Sen)'
                                      : entry['displayName'] as String? ??
                                          '',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Lv.${entry['currentLevel']} ${entry['currentClass']}',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Sort value
                          Text(
                            _sortValue(entry, sortMode),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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
