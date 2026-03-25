import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/aura_card.dart';
import '../../../shared/widgets/stat_badge.dart';
import '../../../shared/widgets/xp_progress_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../providers/character_provider.dart';

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final achievementsAsync = ref.watch(achievementsProvider);

    return SafeArea(
      child: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryAccent),
        ),
        error: (e, _) => Center(
          child: Text('Hata: $e',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
        ),
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                // Title
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Karakter Gelişimi',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textWhite,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Class icon
                Text(user.classIcon, style: const TextStyle(fontSize: 72)),
                const SizedBox(height: 16),

                // Level and class
                Text(
                  'Level ${user.currentLevel} — ${user.currentClass}',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 20),

                // XP bar
                XpProgressBar(
                  currentXp: user.xp,
                  maxXp: user.xpToNextLevel,
                ),
                const SizedBox(height: 32),

                // Stats section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Özellikler',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                StatBadge(
                  emoji: '💪',
                  label: 'Güç',
                  value: user.stats.strength,
                  color: AppTheme.warningOrange,
                ),
                StatBadge(
                  emoji: '🧠',
                  label: 'Zeka',
                  value: user.stats.intelligence,
                  color: AppTheme.statBlue,
                ),
                StatBadge(
                  emoji: '✨',
                  label: 'Karizma',
                  value: user.stats.charisma,
                  color: AppTheme.statPink,
                ),
                StatBadge(
                  emoji: '❤️',
                  label: 'Vitalite',
                  value: user.stats.vitality,
                  color: AppTheme.statRed,
                ),

                const SizedBox(height: 24),

                // Recent XP gains from daily log
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Son Kazanımlar',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Show completed tasks from today's log
                Consumer(
                  builder: (context, ref, child) {
                    final logAsync = ref.watch(todayLogProvider);
                    return logAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (log) {
                        if (log == null || log.completedTasks.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.cardBorderRadius),
                            ),
                            child: Text(
                              'Bugün henüz kazanım yok. Hedeflerini tamamla!',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }

                        final tasks = log.completedTasks.reversed
                            .take(5)
                            .toList();
                        return Column(
                          children: tasks
                              .map((task) => AuraCard(
                                    emoji: '⚡',
                                    title: task,
                                    borderColor: AppTheme.primaryAccent,
                                  ))
                              .toList(),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Achievements section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Başarımlar',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                achievementsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (achievements) {
                    if (achievements.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius:
                              BorderRadius.circular(AppTheme.cardBorderRadius),
                        ),
                        child: Text(
                          'Henüz başarım kazanılmadı. 🏆',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: achievements.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final a = achievements[index];
                          return Container(
                            width: 100,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.cardBorderRadius),
                              border: Border.all(
                                color: AppTheme.primaryAccent.withAlpha(60),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(a.icon,
                                    style: const TextStyle(fontSize: 28)),
                                const SizedBox(height: 4),
                                Text(
                                  a.title,
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textWhite,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
