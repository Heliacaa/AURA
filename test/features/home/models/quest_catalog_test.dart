import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/home/models/daily_quest.dart';
import 'package:aura/shared/models/daily_log_model.dart';
import 'package:aura/shared/models/user_model.dart';

void main() {
  group('Quest catalog', () {
    test('daily rotation is deterministic by date', () {
      final janFirst = DailyQuestCatalog.forDate(DateTime(2024, 1, 1));
      final janSecond = DailyQuestCatalog.forDate(DateTime(2024, 1, 2));

      expect(janFirst.map((quest) => quest.id), [
        DailyQuestIds.sleep,
        DailyQuestIds.calorieCheck,
        DailyQuestIds.waterHalf,
        DailyQuestIds.steps,
      ]);
      expect(
        DailyQuestCatalog.forDate(DateTime(2024, 1, 1)).map((q) => q.id),
        janFirst.map((quest) => quest.id),
      );
      expect(janSecond.map((quest) => quest.id), [
        DailyQuestIds.sleepSevenHours,
        DailyQuestIds.meal,
        DailyQuestIds.water,
        DailyQuestIds.stepsHalf,
      ]);
    });

    test('daily quest progress handles goals and over-budget calories', () {
      final goals = const DailyGoals(
        steps: 10000,
        calories: 2000,
        waterGlasses: 8,
      );
      final log = DailyLogModel(
        date: '2026-05-15',
        timestamp: DateTime(2026, 5, 15),
        sleepHours: 7.5,
        mealsLogged: 1,
        caloriesConsumed: 1800,
        waterGlasses: 4,
        stepCount: 5000,
      );

      expect(
        QuestEvaluator.progressFor(
          quest: DailyQuestCatalog.all.firstWhere(
            (quest) => quest.id == DailyQuestIds.sleepSevenHours,
          ),
          todayLog: log,
          goals: goals,
        ).isComplete,
        isTrue,
      );
      expect(
        QuestEvaluator.progressFor(
          quest: DailyQuestCatalog.all.firstWhere(
            (quest) => quest.id == DailyQuestIds.waterHalf,
          ),
          todayLog: log,
          goals: goals,
        ).isComplete,
        isTrue,
      );
      expect(
        QuestEvaluator.progressFor(
          quest: DailyQuestCatalog.all.firstWhere(
            (quest) => quest.id == DailyQuestIds.calorieCheck,
          ),
          todayLog: log.copyWith(caloriesConsumed: 2200),
          goals: goals,
        ).isComplete,
        isFalse,
      );
    });

    test('combo quests depend on claimed base quests', () {
      final dailyRotation = DailyQuestCatalog.forDate(DateTime(2024, 1, 1));
      final progress = QuestEvaluator.progressFor(
        quest: DailyQuestCatalog.combo,
        todayLog: DailyLogModel.empty('2024-01-01'),
        goals: const DailyGoals(),
        claimedQuestIds: dailyRotation.map((quest) => quest.id).toList(),
        dailyRotation: dailyRotation,
      );

      expect(progress.isComplete, isTrue);
      expect(progress.current, 4);
      expect(progress.target, 4);
    });

    test('weekly progress uses current week logs', () {
      final goals = const DailyGoals(steps: 10000, waterGlasses: 8);
      final logs = [
        DailyLogModel(
          date: '2026-05-11',
          timestamp: DateTime(2026, 5, 11),
          stepCount: 10000,
          waterGlasses: 8,
          mealsLogged: 2,
          claimedQuestIds: const [DailyQuestIds.sleep, DailyQuestIds.meal],
        ),
        DailyLogModel(
          date: '2026-05-12',
          timestamp: DateTime(2026, 5, 12),
          stepCount: 12000,
          waterGlasses: 8,
          mealsLogged: 2,
          claimedQuestIds: const [DailyQuestIds.water, DailyQuestIds.steps],
        ),
        DailyLogModel(
          date: '2026-05-13',
          timestamp: DateTime(2026, 5, 13),
          stepCount: 10000,
          waterGlasses: 8,
          mealsLogged: 1,
          claimedQuestIds: const [DailyQuestIds.sleepSevenHours],
        ),
      ];

      expect(
        QuestEvaluator.progressFor(
          quest: WeeklyQuestCatalog.base.firstWhere(
            (quest) => quest.id == WeeklyQuestIds.steps,
          ),
          todayLog: logs.last,
          goals: goals,
          weekLogs: logs,
        ).isComplete,
        isTrue,
      );
      expect(
        QuestEvaluator.progressFor(
          quest: WeeklyQuestCatalog.base.firstWhere(
            (quest) => quest.id == WeeklyQuestIds.nutrition,
          ),
          todayLog: logs.last,
          goals: goals,
          weekLogs: logs,
        ).isComplete,
        isTrue,
      );
      expect(
        QuestEvaluator.progressFor(
          quest: WeeklyQuestCatalog.base.firstWhere(
            (quest) => quest.id == WeeklyQuestIds.quester,
          ),
          todayLog: logs.last,
          goals: goals,
          weekLogs: logs,
        ).current,
        5,
      );
    });
  });
}
