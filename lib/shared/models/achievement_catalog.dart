import 'achievement_model.dart';

class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final String icon;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  AchievementModel unlock({DateTime? unlockedAt}) {
    return AchievementModel(
      id: id,
      title: title,
      description: description,
      icon: icon,
      unlockedAt: unlockedAt ?? DateTime.now(),
    );
  }
}

class AchievementIds {
  AchievementIds._();

  static const firstQuest = 'first_quest';
  static const dailyCombo = 'daily_combo';
  static const firstWeeklyQuest = 'first_weekly_quest';
  static const weeklyCombo = 'weekly_combo';
  static const weeklySteps = 'weekly_steps_3';
  static const weeklyHydration = 'weekly_hydration_3';
  static const weeklyNutrition = 'weekly_nutrition_5';
}

class AchievementCatalog {
  AchievementCatalog._();

  static const firstQuest = AchievementDefinition(
    id: AchievementIds.firstQuest,
    title: 'İlk Görev',
    description: 'İlk görev ödülünü aldın.',
    icon: '🎯',
  );

  static const dailyCombo = AchievementDefinition(
    id: AchievementIds.dailyCombo,
    title: 'Günlük Kombo',
    description: 'Bir günde 4 görev ödülünü de aldın.',
    icon: '✨',
  );

  static const firstWeeklyQuest = AchievementDefinition(
    id: AchievementIds.firstWeeklyQuest,
    title: 'Haftaya Başladın',
    description: 'İlk haftalık görev ödülünü aldın.',
    icon: '📅',
  );

  static const weeklyCombo = AchievementDefinition(
    id: AchievementIds.weeklyCombo,
    title: 'Haftalık Kombo',
    description: 'Tüm haftalık görevleri tamamladın.',
    icon: '🏆',
  );

  static const weeklySteps = AchievementDefinition(
    id: AchievementIds.weeklySteps,
    title: 'Hareket Serisi',
    description: 'Haftalık adım görevini tamamladın.',
    icon: '🏃',
  );

  static const weeklyHydration = AchievementDefinition(
    id: AchievementIds.weeklyHydration,
    title: 'Hidrasyon Ustası',
    description: 'Haftalık su görevini tamamladın.',
    icon: '🚰',
  );

  static const weeklyNutrition = AchievementDefinition(
    id: AchievementIds.weeklyNutrition,
    title: 'Beslenme Takibi',
    description: 'Haftalık öğün görevini tamamladın.',
    icon: '🥗',
  );

  static const all = [
    firstQuest,
    dailyCombo,
    firstWeeklyQuest,
    weeklyCombo,
    weeklySteps,
    weeklyHydration,
    weeklyNutrition,
  ];

  static AchievementDefinition? byId(String id) {
    for (final achievement in all) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }
}
