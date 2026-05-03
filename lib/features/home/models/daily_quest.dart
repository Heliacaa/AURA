import '../../../shared/models/daily_log_model.dart';
import '../../../shared/models/user_model.dart';

class DailyQuest {
  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final int xpReward;
  final Map<String, int> statDeltas;
  final String taskDescription;

  const DailyQuest({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.xpReward,
    required this.statDeltas,
    required this.taskDescription,
  });

  bool isComplete(DailyLogModel log, DailyGoals goals) {
    switch (id) {
      case DailyQuestIds.sleep:
        return log.sleepHours > 0;
      case DailyQuestIds.meal:
        return log.mealsLogged > 0;
      case DailyQuestIds.water:
        return log.waterGlasses >= goals.waterGlasses;
      case DailyQuestIds.steps:
        return log.stepCount >= goals.steps;
      default:
        return false;
    }
  }
}

class DailyQuestIds {
  DailyQuestIds._();

  static const sleep = 'sleep_log';
  static const meal = 'meal_log';
  static const water = 'water_goal';
  static const steps = 'step_goal';
}

class DailyQuestCatalog {
  DailyQuestCatalog._();

  static const all = [
    DailyQuest(
      id: DailyQuestIds.sleep,
      emoji: '😴',
      title: 'Uyku Kaydı',
      subtitle: 'Gece uykunu kaydet',
      xpReward: 25,
      statDeltas: {'vitality': 3},
      taskDescription: '+25 XP (Uyku görevi tamamlandı)',
    ),
    DailyQuest(
      id: DailyQuestIds.meal,
      emoji: '🍽️',
      title: 'Yemek Kaydı',
      subtitle: 'En az 1 öğün tarayıp kaydet',
      xpReward: 20,
      statDeltas: {'vitality': 2},
      taskDescription: '+20 XP (Yemek görevi tamamlandı)',
    ),
    DailyQuest(
      id: DailyQuestIds.water,
      emoji: '💧',
      title: 'Su Hedefi',
      subtitle: 'Günlük su hedefini tamamla',
      xpReward: 20,
      statDeltas: {'vitality': 2},
      taskDescription: '+20 XP (Su görevi tamamlandı)',
    ),
    DailyQuest(
      id: DailyQuestIds.steps,
      emoji: '👟',
      title: 'Adım Hedefi',
      subtitle: 'Günlük adım hedefini tamamla',
      xpReward: 35,
      statDeltas: {'strength': 4},
      taskDescription: '+35 XP (Adım görevi tamamlandı)',
    ),
  ];
}
