import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/shared/models/weekly_quest_log_model.dart';

void main() {
  group('WeeklyQuestLogModel', () {
    test('empty factory creates week log defaults', () {
      final log = WeeklyQuestLogModel.empty('2026-W20');

      expect(log.weekKey, '2026-W20');
      expect(log.claimedQuestIds, isEmpty);
      expect(log.xpEarned, 0);
      expect(log.completedTasks, isEmpty);
    });

    test('toFirestore serializes fields', () {
      final log = WeeklyQuestLogModel(
        weekKey: '2026-W20',
        updatedAt: DateTime(2026, 5, 15),
        claimedQuestIds: const ['weekly_steps_3'],
        xpEarned: 90,
        completedTasks: const ['+90 XP'],
      );

      final map = log.toFirestore();
      expect(map['weekKey'], '2026-W20');
      expect(map['claimedQuestIds'], ['weekly_steps_3']);
      expect(map['xpEarned'], 90);
      expect(map['completedTasks'], ['+90 XP']);
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('fromFirestore parses missing values safely', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc('uid1')
          .collection('weeklyQuestLogs')
          .doc('2026-W20')
          .set({'weekKey': '2026-W20'});

      final doc = await firestore
          .collection('users')
          .doc('uid1')
          .collection('weeklyQuestLogs')
          .doc('2026-W20')
          .get();

      final log = WeeklyQuestLogModel.fromFirestore(doc);
      expect(log.weekKey, '2026-W20');
      expect(log.claimedQuestIds, isEmpty);
      expect(log.xpEarned, 0);
    });
  });
}
