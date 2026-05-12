import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id;
  final String title;
  final String description;
  final String type; // 'steps', 'water' vb.
  final int currentAmount;
  final int targetAmount;
  final String unit;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime endDate;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.currentAmount,
    required this.targetAmount,
    required this.unit,
    required this.participants,
    required this.createdAt,
    required this.endDate,
  });

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    try {
      var data = doc.data() as Map<String, dynamic>;
      return Challenge(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        type: data['type'] ?? 'unknown',
        currentAmount: (data['currentAmount'] ?? 0).toInt(),
        targetAmount: (data['targetAmount'] ?? 0).toInt(),
        unit: data['unit'] ?? '',
        participants: List<String>.from(data['participants'] ?? []),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      // Fallback in case of parsing errors
      return Challenge.empty(doc.id);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'currentAmount': currentAmount,
      'targetAmount': targetAmount,
      'unit': unit,
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
      'endDate': Timestamp.fromDate(endDate),
    };
  }

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  factory Challenge.empty(String id) {
    return Challenge(
      id: id,
      title: 'Hata',
      description: 'Meydan okuma yüklenemedi.',
      type: 'unknown',
      currentAmount: 0,
      targetAmount: 1,
      unit: '',
      participants: [],
      createdAt: DateTime.now(),
      endDate: DateTime.now(),
    );
  }
}
