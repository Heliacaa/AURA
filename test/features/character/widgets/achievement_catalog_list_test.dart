import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/character/widgets/achievement_catalog_list.dart';
import 'package:aura/shared/models/achievement_catalog.dart';

void main() {
  testWidgets('AchievementCatalogList shows unlocked and locked badges', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AchievementCatalogList(
            unlockedAchievements: [
              AchievementCatalog.firstQuest.unlock(
                unlockedAt: DateTime(2026, 5, 15),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('İlk Görev'), findsOneWidget);
    expect(find.text('Açıldı'), findsOneWidget);
    expect(find.text('Kilitli'), findsWidgets);
  });
}
