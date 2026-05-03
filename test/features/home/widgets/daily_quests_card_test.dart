import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/home/widgets/daily_quests_card.dart';
import 'package:aura/shared/models/daily_log_model.dart';
import 'package:aura/shared/models/user_model.dart';

void main() {
  testWidgets('DailyQuestsCard shows claimed, ready, and locked states', (
    tester,
  ) async {
    final log = DailyLogModel(
      date: '2026-05-03',
      timestamp: DateTime(2026, 5, 3),
      sleepHours: 7.5,
      mealsLogged: 1,
      waterGlasses: 2,
      stepCount: 3000,
      claimedQuestIds: const ['sleep_log'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyQuestsCard(
            uid: 'uid1',
            log: log,
            goals: const DailyGoals(steps: 10000, waterGlasses: 8),
          ),
        ),
      ),
    );

    expect(find.text('Günlük Görevler'), findsOneWidget);
    expect(find.text('Uyku Kaydı'), findsOneWidget);
    expect(find.text('Yemek Kaydı'), findsOneWidget);
    expect(find.text('Alındı'), findsOneWidget);
    expect(find.text('Al'), findsOneWidget);
    expect(find.text('Kilitli'), findsNWidgets(2));
  });
}
