import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String? id;
  final DateTime timestamp;
  final String role; // "user" | "assistant"
  final String content;

  const ChatMessageModel({
    this.id,
    required this.timestamp,
    required this.role,
    required this.content,
  });

  bool get isUser => role == 'user';

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessageModel(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: data['role'] as String? ?? 'user',
      content: data['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'timestamp': Timestamp.fromDate(timestamp),
    'role': role,
    'content': content,
  };

  factory ChatMessageModel.user(String content) {
    return ChatMessageModel(
      timestamp: DateTime.now(),
      role: 'user',
      content: content,
    );
  }

  factory ChatMessageModel.assistant(String content) {
    return ChatMessageModel(
      timestamp: DateTime.now(),
      role: 'assistant',
      content: content,
    );
  }
}
