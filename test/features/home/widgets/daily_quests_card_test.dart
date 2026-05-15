import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/home/models/daily_quest.dart';
import 'package:aura/features/home/providers/home_provider.dart';
import 'package:aura/features/home/widgets/daily_quests_card.dart';
import 'package:aura/shared/models/daily_log_model.dart';
import 'package:aura/shared/models/user_model.dart';
import 'package:aura/shared/models/weekly_quest_log_model.dart';

void main() {
  Widget buildSubject(
    DailyLogModel log, {
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: DailyQuestsCard(
            uid: 'uid1',
            log: log,
            goals: const DailyGoals(steps: 10000, waterGlasses: 8),
          ),
        ),
      ),
    );
  }

  testWidgets('quest board shows claimed, ready, and locked daily states', (
    tester,
  ) async {
    final rotation = DailyQuestCatalog.forDate(DateTime.now());
    final log = DailyLogModel(
      date: '2026-05-15',
      timestamp: DateTime(2026, 5, 15),
      sleepHours: 7.5,
      mealsLogged: 1,
      caloriesConsumed: 1500,
      waterGlasses: 2,
      stepCount: 3000,
      claimedQuestIds: [rotation.first.id],
    );

    await tester.pumpWidget(buildSubject(log));

    expect(find.text('Görev Panosu'), findsOneWidget);
    expect(find.text('Günlük'), findsOneWidget);
    expect(find.text('Haftalık'), findsOneWidget);
    expect(find.text('Alındı'), findsOneWidget);
    expect(find.text('Al'), findsOneWidget);
    expect(find.text('Kilitli'), findsNWidgets(3));
  });

  testWidgets('all daily base quests can be ready while combo is locked', (
    tester,
  ) async {
    final log = DailyLogModel(
      date: '2026-05-15',
      timestamp: DateTime(2026, 5, 15),
      sleepHours: 7.5,
      mealsLogged: 1,
      caloriesConsumed: 1500,
      waterGlasses: 8,
      stepCount: 12000,
    );

    await tester.pumpWidget(buildSubject(log));

    expect(find.text('Alındı'), findsNothing);
    expect(find.text('Al'), findsNWidgets(4));
    expect(find.text('Kilitli'), findsOneWidget);
  });

  testWidgets('daily combo becomes ready after all base rewards are claimed', (
    tester,
  ) async {
    final rotation = DailyQuestCatalog.forDate(DateTime.now());
    final log = DailyLogModel(
      date: '2026-05-15',
      timestamp: DateTime(2026, 5, 15),
      sleepHours: 7.5,
      mealsLogged: 1,
      caloriesConsumed: 1500,
      waterGlasses: 8,
      stepCount: 12000,
      claimedQuestIds: rotation.map((quest) => quest.id).toList(),
    );

    await tester.pumpWidget(buildSubject(log));

    expect(find.text('Alındı'), findsNWidgets(4));
    expect(find.text('Al'), findsOneWidget);
    expect(find.text('Günlük Kombo'), findsOneWidget);
  });

  testWidgets('weekly tab shows ready and locked weekly quest states', (
    tester,
  ) async {
    final weekLogs = [
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
        stepCount: 11000,
        waterGlasses: 8,
        mealsLogged: 2,
        claimedQuestIds: const [DailyQuestIds.water, DailyQuestIds.steps],
      ),
      DailyLogModel(
        date: '2026-05-13',
        timestamp: DateTime(2026, 5, 13),
        stepCount: 12000,
        waterGlasses: 8,
        mealsLogged: 1,
        claimedQuestIds: const [DailyQuestIds.sleepSevenHours],
      ),
    ];

    await tester.pumpWidget(
      buildSubject(
        weekLogs.last,
        overrides: [
          currentWeekLogsProvider.overrideWith((ref) async => weekLogs),
          weeklyQuestLogProvider.overrideWith(
            (ref) => Stream.value(WeeklyQuestLogModel.empty('2026-W20')),
          ),
        ],
      ),
    );

    await tester.tap(find.text('Haftalık'));
    await tester.pumpAndSettle();

    expect(find.text('Haftalık Görevci'), findsOneWidget);
    expect(find.text('3 Gün Hareket'), findsOneWidget);
    expect(find.text('Al'), findsNWidgets(3));
    expect(find.text('Kilitli'), findsNWidgets(2));
  });

  testWidgets('weekly tab still renders when weekly reward log cannot sync', (
    tester,
  ) async {
    final weekLogs = [
      DailyLogModel(
        date: '2026-05-11',
        timestamp: DateTime(2026, 5, 11),
        stepCount: 10000,
        waterGlasses: 8,
        mealsLogged: 2,
      ),
    ];

    await tester.pumpWidget(
      buildSubject(
        weekLogs.first,
        overrides: [
          currentWeekLogsProvider.overrideWith((ref) async => weekLogs),
          weeklyQuestLogProvider.overrideWith(
            (ref) => Stream<WeeklyQuestLogModel?>.error(
              Exception('permission-denied'),
            ),
          ),
        ],
      ),
    );

    await tester.tap(find.text('Haftalık'));
    await tester.pumpAndSettle();

    expect(find.text('Haftalık Görevci'), findsOneWidget);
    expect(
      find.textContaining('Haftalık ödül durumu senkronize edilemedi'),
      findsOneWidget,
    );
    expect(find.text('Görevler yüklenemedi.'), findsNothing);
  });
}
