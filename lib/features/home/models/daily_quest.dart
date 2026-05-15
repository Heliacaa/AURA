import '../../../shared/models/daily_log_model.dart';
import '../../../shared/models/user_model.dart';

enum QuestCadence { daily, weekly }

enum QuestStatus { locked, ready, claimed }

class QuestDefinition {
  final String id;
  final QuestCadence cadence;
  final String emoji;
  final String title;
  final String subtitle;
  final int xpReward;
  final Map<String, int> statDeltas;
  final String taskDescription;

  const QuestDefinition({
    required this.id,
    required this.cadence,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.xpReward,
    required this.statDeltas,
    required this.taskDescription,
  });

  bool isComplete(
    DailyLogModel? todayLog,
    DailyGoals goals, {
    List<DailyLogModel> weekLogs = const [],
    List<String> claimedQuestIds = const [],
    List<QuestDefinition> dailyRotation = const [],
  }) {
    return QuestEvaluator.progressFor(
      quest: this,
      todayLog: todayLog,
      goals: goals,
      weekLogs: weekLogs,
      claimedQuestIds: claimedQuestIds,
      dailyRotation: dailyRotation,
    ).isComplete;
  }
}

class QuestProgress {
  final num current;
  final num target;
  final String unit;
  final bool isComplete;

  const QuestProgress({
    required this.current,
    required this.target,
    required this.unit,
    required this.isComplete,
  });

  double get ratio => target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);

  String get label {
    final currentLabel = _format(current);
    final targetLabel = _format(target);
    return '$currentLabel / $targetLabel $unit';
  }

  String _format(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class QuestEvaluator {
  QuestEvaluator._();

  static QuestProgress progressFor({
    required QuestDefinition quest,
    required DailyLogModel? todayLog,
    required DailyGoals goals,
    List<DailyLogModel> weekLogs = const [],
    List<String> claimedQuestIds = const [],
    List<QuestDefinition> dailyRotation = const [],
  }) {
    final log = todayLog;
    switch (quest.id) {
      case DailyQuestIds.sleep:
        final current = log == null || log.sleepHours <= 0 ? 0 : 1;
        return QuestProgress(
          current: current,
          target: 1,
          unit: 'kayıt',
          isComplete: current >= 1,
        );
      case DailyQuestIds.sleepSevenHours:
        final current = log?.sleepHours ?? 0;
        return QuestProgress(
          current: current,
          target: 7,
          unit: 'saat',
          isComplete: current >= 7,
        );
      case DailyQuestIds.meal:
        final current = log?.mealsLogged ?? 0;
        return QuestProgress(
          current: current,
          target: 1,
          unit: 'öğün',
          isComplete: current >= 1,
        );
      case DailyQuestIds.calorieCheck:
        final current = log?.caloriesConsumed ?? 0;
        final target = goals.calories;
        return QuestProgress(
          current: current,
          target: target,
          unit: 'kcal',
          isComplete: current > 0 && current <= target,
        );
      case DailyQuestIds.waterHalf:
        final target = (goals.waterGlasses / 2).ceil().clamp(1, 999999);
        final current = log?.waterGlasses ?? 0;
        return QuestProgress(
          current: current,
          target: target,
          unit: 'bardak',
          isComplete: current >= target,
        );
      case DailyQuestIds.water:
        final current = log?.waterGlasses ?? 0;
        return QuestProgress(
          current: current,
          target: goals.waterGlasses,
          unit: 'bardak',
          isComplete: current >= goals.waterGlasses,
        );
      case DailyQuestIds.stepsHalf:
        final target = (goals.steps / 2).ceil().clamp(1, 999999);
        final current = log?.stepCount ?? 0;
        return QuestProgress(
          current: current,
          target: target,
          unit: 'adım',
          isComplete: current >= target,
        );
      case DailyQuestIds.steps:
        final current = log?.stepCount ?? 0;
        return QuestProgress(
          current: current,
          target: goals.steps,
          unit: 'adım',
          isComplete: current >= goals.steps,
        );
      case DailyQuestIds.combo:
        final baseQuests = dailyRotation.isEmpty
            ? DailyQuestCatalog.forDate(DateTime.now())
            : dailyRotation;
        final current = baseQuests
            .where((item) => claimedQuestIds.contains(item.id))
            .length;
        return QuestProgress(
          current: current,
          target: baseQuests.length,
          unit: 'görev',
          isComplete: current >= baseQuests.length,
        );
      case WeeklyQuestIds.quester:
        final current = weekLogs.fold<int>(
          0,
          (sum, item) =>
              sum +
              item.claimedQuestIds
                  .where(DailyQuestCatalog.dailyBaseIds.contains)
                  .length,
        );
        return QuestProgress(
          current: current,
          target: 10,
          unit: 'günlük ödül',
          isComplete: current >= 10,
        );
      case WeeklyQuestIds.steps:
        final current = weekLogs
            .where((item) => item.stepCount >= goals.steps)
            .length;
        return QuestProgress(
          current: current,
          target: 3,
          unit: 'gün',
          isComplete: current >= 3,
        );
      case WeeklyQuestIds.hydration:
        final current = weekLogs
            .where((item) => item.waterGlasses >= goals.waterGlasses)
            .length;
        return QuestProgress(
          current: current,
          target: 3,
          unit: 'gün',
          isComplete: current >= 3,
        );
      case WeeklyQuestIds.nutrition:
        final current = weekLogs.fold<int>(
          0,
          (sum, item) => sum + item.mealsLogged,
        );
        return QuestProgress(
          current: current,
          target: 5,
          unit: 'öğün',
          isComplete: current >= 5,
        );
      case WeeklyQuestIds.combo:
        final current = WeeklyQuestCatalog.base
            .where((item) => claimedQuestIds.contains(item.id))
            .length;
        return QuestProgress(
          current: current,
          target: WeeklyQuestCatalog.base.length,
          unit: 'haftalık görev',
          isComplete: current >= WeeklyQuestCatalog.base.length,
        );
      default:
        return const QuestProgress(
          current: 0,
          target: 1,
          unit: '',
          isComplete: false,
        );
    }
  }

  static QuestStatus statusFor({
    required QuestDefinition quest,
    required QuestProgress progress,
    required List<String> claimedQuestIds,
  }) {
    if (claimedQuestIds.contains(quest.id)) return QuestStatus.claimed;
    if (progress.isComplete) return QuestStatus.ready;
    return QuestStatus.locked;
  }
}

class DailyQuestIds {
  DailyQuestIds._();

  static const sleep = 'sleep_log';
  static const sleepSevenHours = 'sleep_7h';
  static const meal = 'meal_log';
  static const calorieCheck = 'calorie_check';
  static const waterHalf = 'water_half';
  static const water = 'water_goal';
  static const stepsHalf = 'steps_half';
  static const steps = 'step_goal';
  static const combo = 'daily_combo';
}

class WeeklyQuestIds {
  WeeklyQuestIds._();

  static const quester = 'weekly_quester';
  static const steps = 'weekly_steps_3';
  static const hydration = 'weekly_hydration_3';
  static const nutrition = 'weekly_nutrition_5';
  static const combo = 'weekly_combo';
}

class DailyQuestCatalog {
  DailyQuestCatalog._();

  static const recovery = [
    QuestDefinition(
      id: DailyQuestIds.sleep,
      cadence: QuestCadence.daily,
      emoji: '😴',
      title: 'Uyku Kaydı',
      subtitle: 'Gece uykunu kaydet',
      xpReward: 25,
      statDeltas: {'vitality': 3},
      taskDescription: '+25 XP (Uyku görevi tamamlandı)',
    ),
    QuestDefinition(
      id: DailyQuestIds.sleepSevenHours,
      cadence: QuestCadence.daily,
      emoji: '🌙',
      title: '7 Saat Uyku',
      subtitle: 'En az 7 saat uyku kaydet',
      xpReward: 30,
      statDeltas: {'vitality': 4},
      taskDescription: '+30 XP (7 saat uyku görevi tamamlandı)',
    ),
  ];

  static const nutrition = [
    QuestDefinition(
      id: DailyQuestIds.meal,
      cadence: QuestCadence.daily,
      emoji: '🍽️',
      title: 'Yemek Kaydı',
      subtitle: 'En az 1 öğün tarayıp kaydet',
      xpReward: 20,
      statDeltas: {'vitality': 2},
      taskDescription: '+20 XP (Yemek görevi tamamlandı)',
    ),
    QuestDefinition(
      id: DailyQuestIds.calorieCheck,
      cadence: QuestCadence.daily,
      emoji: '📊',
      title: 'Kalori Kontrolü',
      subtitle: 'Kalori bütçeni takip et',
      xpReward: 25,
      statDeltas: {'intelligence': 2},
      taskDescription: '+25 XP (Kalori kontrolü tamamlandı)',
    ),
  ];

  static const hydration = [
    QuestDefinition(
      id: DailyQuestIds.waterHalf,
      cadence: QuestCadence.daily,
      emoji: '💧',
      title: 'Yarı Su Hedefi',
      subtitle: 'Günlük su hedefinin yarısına ulaş',
      xpReward: 10,
      statDeltas: {'vitality': 1},
      taskDescription: '+10 XP (Yarı su hedefi tamamlandı)',
    ),
    QuestDefinition(
      id: DailyQuestIds.water,
      cadence: QuestCadence.daily,
      emoji: '💧',
      title: 'Su Hedefi',
      subtitle: 'Günlük su hedefini tamamla',
      xpReward: 20,
      statDeltas: {'vitality': 2},
      taskDescription: '+20 XP (Su görevi tamamlandı)',
    ),
  ];

  static const movement = [
    QuestDefinition(
      id: DailyQuestIds.stepsHalf,
      cadence: QuestCadence.daily,
      emoji: '👟',
      title: 'Yarım Adım Hedefi',
      subtitle: 'Günlük adım hedefinin yarısına ulaş',
      xpReward: 15,
      statDeltas: {'strength': 2},
      taskDescription: '+15 XP (Yarım adım hedefi tamamlandı)',
    ),
    QuestDefinition(
      id: DailyQuestIds.steps,
      cadence: QuestCadence.daily,
      emoji: '👟',
      title: 'Adım Hedefi',
      subtitle: 'Günlük adım hedefini tamamla',
      xpReward: 35,
      statDeltas: {'strength': 4},
      taskDescription: '+35 XP (Adım görevi tamamlandı)',
    ),
  ];

  static const combo = QuestDefinition(
    id: DailyQuestIds.combo,
    cadence: QuestCadence.daily,
    emoji: '✨',
    title: 'Günlük Kombo',
    subtitle: 'Bugünün 4 görev ödülünü de al',
    xpReward: 40,
    statDeltas: {'charisma': 2, 'vitality': 2},
    taskDescription: '+40 XP (Günlük kombo tamamlandı)',
  );

  static const all = [
    ...recovery,
    ...nutrition,
    ...hydration,
    ...movement,
    combo,
  ];

  static const dailyBaseIds = {
    DailyQuestIds.sleep,
    DailyQuestIds.sleepSevenHours,
    DailyQuestIds.meal,
    DailyQuestIds.calorieCheck,
    DailyQuestIds.waterHalf,
    DailyQuestIds.water,
    DailyQuestIds.stepsHalf,
    DailyQuestIds.steps,
  };

  static List<QuestDefinition> forDate(DateTime date) {
    final seed = _dateSeed(date);
    return [
      recovery[_rotatingIndex(seed, recovery.length, 0)],
      nutrition[_rotatingIndex(seed, nutrition.length, 1)],
      hydration[_rotatingIndex(seed, hydration.length, 2)],
      movement[_rotatingIndex(seed, movement.length, 3)],
    ];
  }

  static int _dateSeed(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.difference(DateTime(2024)).inDays;
  }

  static int _rotatingIndex(int seed, int length, int offset) {
    final value = seed + offset;
    return value % length;
  }
}

class WeeklyQuestCatalog {
  WeeklyQuestCatalog._();

  static const base = [
    QuestDefinition(
      id: WeeklyQuestIds.quester,
      cadence: QuestCadence.weekly,
      emoji: '🎯',
      title: 'Haftalık Görevci',
      subtitle: '10 günlük görev ödülü al',
      xpReward: 100,
      statDeltas: {'charisma': 4},
      taskDescription: '+100 XP (Haftalık görevci tamamlandı)',
    ),
    QuestDefinition(
      id: WeeklyQuestIds.steps,
      cadence: QuestCadence.weekly,
      emoji: '🏃',
      title: '3 Gün Hareket',
      subtitle: '3 gün adım hedefine ulaş',
      xpReward: 90,
      statDeltas: {'strength': 6},
      taskDescription: '+90 XP (Haftalık adım görevi tamamlandı)',
    ),
    QuestDefinition(
      id: WeeklyQuestIds.hydration,
      cadence: QuestCadence.weekly,
      emoji: '🚰',
      title: '3 Gün Hidrasyon',
      subtitle: '3 gün su hedefine ulaş',
      xpReward: 75,
      statDeltas: {'vitality': 5},
      taskDescription: '+75 XP (Haftalık su görevi tamamlandı)',
    ),
    QuestDefinition(
      id: WeeklyQuestIds.nutrition,
      cadence: QuestCadence.weekly,
      emoji: '🥗',
      title: '5 Öğün Takibi',
      subtitle: 'Hafta içinde 5 öğün kaydet',
      xpReward: 80,
      statDeltas: {'vitality': 3, 'intelligence': 2},
      taskDescription: '+80 XP (Haftalık beslenme görevi tamamlandı)',
    ),
  ];

  static const combo = QuestDefinition(
    id: WeeklyQuestIds.combo,
    cadence: QuestCadence.weekly,
    emoji: '🏆',
    title: 'Haftalık Kombo',
    subtitle: 'Tüm haftalık görev ödüllerini al',
    xpReward: 150,
    statDeltas: {
      'strength': 2,
      'intelligence': 2,
      'charisma': 2,
      'vitality': 2,
    },
    taskDescription: '+150 XP (Haftalık kombo tamamlandı)',
  );

  static const all = [...base, combo];
}
