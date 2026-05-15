import 'package:flutter_test/flutter_test.dart';
import 'package:aura/shared/models/meal_model.dart';

void main() {
  group('MealModel', () {
    test('fromJson parses correctly', () {
      final meal = MealModel.fromJson({
        'foodName': 'Pizza',
        'calories': 350,
        'protein': 15.5,
        'carbs': 40.0,
        'fat': 12.3,
        'advice': 'Dengeli bir öğün.',
      });

      expect(meal.detectedFood, 'Pizza');
      expect(meal.calories, 350);
      expect(meal.protein, 15.5);
      expect(meal.carbs, 40.0);
      expect(meal.fat, 12.3);
      expect(meal.aiAdvice, 'Dengeli bir öğün.');
    });

    test('fromJson handles nulls and missing', () {
      final meal = MealModel.fromJson({});
      expect(meal.detectedFood, '');
      expect(meal.calories, 0);
      expect(meal.protein, 0.0);
      expect(meal.carbs, 0.0);
      expect(meal.fat, 0.0);
      expect(meal.aiAdvice, '');
    });

    test('toFirestore serializes', () {
      final meal = MealModel(
        timestamp: DateTime(2024, 6, 15, 12, 30),
        detectedFood: 'Salad',
        calories: 200,
        protein: 10.0,
        carbs: 25.0,
        fat: 5.0,
        aiAdvice: 'Healthy choice!',
        imageUrl: 'https://example.com/img.jpg',
      );

      final map = meal.toFirestore();
      expect(map['detectedFood'], 'Salad');
      expect(map['calories'], 200);
      expect(map['protein'], 10.0);
      expect(map['carbs'], 25.0);
      expect(map['fat'], 5.0);
      expect(map['aiAdvice'], 'Healthy choice!');
      expect(map['imageUrl'], 'https://example.com/img.jpg');
    });

    test('copyWith updates imageUrl and timestamp', () {
      final meal = MealModel(
        timestamp: DateTime(2024, 6, 15),
        detectedFood: 'Rice',
        calories: 300,
        protein: 5.0,
        carbs: 60.0,
        fat: 2.0,
      );

      final savedAt = DateTime(2024, 6, 16, 10, 30);
      final updated = meal.copyWith(imageUrl: 'new_url', timestamp: savedAt);
      expect(updated.imageUrl, 'new_url');
      expect(updated.timestamp, savedAt);
      expect(updated.detectedFood, 'Rice');
      expect(updated.calories, 300);
    });
  });
}
