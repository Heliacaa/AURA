import 'package:cloud_firestore/cloud_firestore.dart';

class MealModel {
  final String? id;
  final DateTime timestamp;
  final String imageUrl;
  final String detectedFood;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String aiAdvice;

  const MealModel({
    this.id,
    required this.timestamp,
    this.imageUrl = '',
    required this.detectedFood,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.aiAdvice = '',
  });

  factory MealModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MealModel(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String? ?? '',
      detectedFood: data['detectedFood'] as String? ?? '',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
      aiAdvice: data['aiAdvice'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'timestamp': Timestamp.fromDate(timestamp),
    'imageUrl': imageUrl,
    'detectedFood': detectedFood,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'aiAdvice': aiAdvice,
  };

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      timestamp: DateTime.now(),
      detectedFood: json['foodName'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      aiAdvice: json['advice'] as String? ?? '',
    );
  }

  MealModel copyWith({String? imageUrl}) {
    return MealModel(
      id: id,
      timestamp: timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      detectedFood: detectedFood,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      aiAdvice: aiAdvice,
    );
  }
}
