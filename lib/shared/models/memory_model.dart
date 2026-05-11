import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryModel {
  final String? id;
  final String content;
  final String category; // exam, health, social, work, goal
  final DateTime extractedAt;
  final DateTime? relevantDate;
  final String? source; // chat message ID

  const MemoryModel({
    this.id,
    required this.content,
    required this.category,
    required this.extractedAt,
    this.relevantDate,
    this.source,
  });

  factory MemoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MemoryModel(
      id: doc.id,
      content: data['content'] as String? ?? '',
      category: data['category'] as String? ?? 'general',
      extractedAt:
          (data['extractedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      relevantDate: (data['relevantDate'] as Timestamp?)?.toDate(),
      source: data['source'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'content': content,
    'category': category,
    'extractedAt': Timestamp.fromDate(extractedAt),
    if (relevantDate != null) 'relevantDate': Timestamp.fromDate(relevantDate!),
    if (source != null) 'source': source,
  };

  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    DateTime? relevant;
    if (json['relevantDate'] != null) {
      try {
        relevant = DateTime.parse(json['relevantDate'] as String);
      } catch (_) {}
    }
    return MemoryModel(
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      extractedAt: DateTime.now(),
      relevantDate: relevant,
    );
  }
}
