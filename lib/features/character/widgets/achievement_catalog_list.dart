import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/achievement_catalog.dart';
import '../../../shared/models/achievement_model.dart';

class AchievementCatalogList extends StatelessWidget {
  final List<AchievementModel> unlockedAchievements;

  const AchievementCatalogList({super.key, required this.unlockedAchievements});

  @override
  Widget build(BuildContext context) {
    final unlockedById = {
      for (final achievement in unlockedAchievements)
        achievement.id: achievement,
    };
    final catalogIds = AchievementCatalog.all
        .map((achievement) => achievement.id)
        .toSet();
    final legacyDefinitions = unlockedAchievements
        .where((achievement) => !catalogIds.contains(achievement.id))
        .map(
          (achievement) => AchievementDefinition(
            id: achievement.id,
            title: achievement.title,
            description: achievement.description,
            icon: achievement.icon,
          ),
        );
    final definitions = [...AchievementCatalog.all, ...legacyDefinitions];

    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: definitions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final definition = definitions[index];
          final unlocked = unlockedById.containsKey(definition.id);
          return _AchievementBadge(definition: definition, unlocked: unlocked);
        },
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final AchievementDefinition definition;
  final bool unlocked;

  const _AchievementBadge({required this.definition, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: unlocked ? 1 : 0.45,
      child: Container(
        width: 106,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          border: Border.all(
            color: unlocked
                ? AppTheme.primaryAccent.withAlpha(90)
                : AppTheme.textSecondary.withAlpha(35),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              unlocked ? definition.icon : '🔒',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 5),
            Text(
              definition.title,
              style: GoogleFonts.poppins(
                color: AppTheme.textWhite,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              unlocked ? 'Açıldı' : 'Kilitli',
              style: GoogleFonts.poppins(
                color: unlocked
                    ? AppTheme.secondaryAccent
                    : AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
