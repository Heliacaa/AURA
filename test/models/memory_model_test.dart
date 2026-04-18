import 'package:flutter_test/flutter_test.dart';
import 'package:aura/shared/models/memory_model.dart';

void main() {
  group('MemoryModel', () {
    test('fromJson parses basic fields', () {
      final memory = MemoryModel.fromJson({
        'content': 'User has an exam on Monday',
        'category': 'exam',
      });

      expect(memory.content, 'User has an exam on Monday');
      expect(memory.category, 'exam');
      expect(memory.relevantDate, isNull);
    });

    test('fromJson parses relevantDate', () {
      final memory = MemoryModel.fromJson({
        'content': 'Doctor appointment',
        'category': 'health',
        'relevantDate': '2024-07-15',
      });

      expect(memory.relevantDate, isNotNull);
      expect(memory.relevantDate!.year, 2024);
      expect(memory.relevantDate!.month, 7);
      expect(memory.relevantDate!.day, 15);
    });

    test('fromJson handles invalid relevantDate', () {
      final memory = MemoryModel.fromJson({
        'content': 'Something',
        'category': 'general',
        'relevantDate': 'not-a-date',
      });

      expect(memory.relevantDate, isNull);
    });

    test('fromJson handles missing fields', () {
      final memory = MemoryModel.fromJson({});
      expect(memory.content, '');
      expect(memory.category, 'general');
    });

    test('toFirestore serializes correctly', () {
      final memory = MemoryModel(
        content: 'Test memory',
        category: 'work',
        extractedAt: DateTime(2024, 6, 15),
        relevantDate: DateTime(2024, 7, 1),
        source: 'msg-123',
      );

      final map = memory.toFirestore();
      expect(map['content'], 'Test memory');
      expect(map['category'], 'work');
      expect(map.containsKey('relevantDate'), isTrue);
      expect(map.containsKey('source'), isTrue);
      expect(map['source'], 'msg-123');
    });

    test('toFirestore omits null optional fields', () {
      final memory = MemoryModel(
        content: 'Simple memory',
        category: 'social',
        extractedAt: DateTime(2024, 6, 15),
      );

      final map = memory.toFirestore();
      expect(map.containsKey('relevantDate'), isFalse);
      expect(map.containsKey('source'), isFalse);
    });
  });
}
