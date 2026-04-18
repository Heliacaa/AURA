import 'package:flutter_test/flutter_test.dart';
import 'package:aura/shared/models/chat_message_model.dart';

void main() {
  group('ChatMessageModel', () {
    test('user factory creates user message', () {
      final msg = ChatMessageModel.user('Hello');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
      expect(msg.isUser, isTrue);
    });

    test('assistant factory creates assistant message', () {
      final msg = ChatMessageModel.assistant('Hi there');
      expect(msg.role, 'assistant');
      expect(msg.content, 'Hi there');
      expect(msg.isUser, isFalse);
    });

    test('toFirestore serializes', () {
      final msg = ChatMessageModel(
        timestamp: DateTime(2024, 6, 15, 12, 0),
        role: 'user',
        content: 'Test message',
      );

      final map = msg.toFirestore();
      expect(map['role'], 'user');
      expect(map['content'], 'Test message');
    });
  });
}
