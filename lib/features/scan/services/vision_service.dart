import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../shared/models/meal_model.dart';

class VisionService {
  VisionService._();
  static final instance = VisionService._();

  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  GenerativeModel? _model;

  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    return _model!;
  }

  /// Analyze food image and return MealModel with goal-aware advice
  Future<MealModel> analyzeFood(
    File imageFile, {
    int calorieGoal = 2000,
    int caloriesConsumed = 0,
    double proteinConsumed = 0,
    double carbsConsumed = 0,
    double fatConsumed = 0,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('API anahtarı yapılandırılmamış. Lütfen .env dosyanızı kontrol edin.');
    }

    final imageBytes = await imageFile.readAsBytes();
    final remaining = calorieGoal - caloriesConsumed;

    final prompt = Content.multi([
      TextPart(
        'Bu yemeği tanımla. Şu JSON formatında yanıt ver: '
        '{"foodName": "string", "calories": int, "protein": double, '
        '"carbs": double, "fat": double, "advice": "string"}. '
        'Sadece JSON döndür, başka bir şey yazma. '
        'Kullanıcının günlük kalori hedefi: $calorieGoal kcal. '
        'Bugün şu ana kadar tüketilen: $caloriesConsumed kcal '
        '(Protein: ${proteinConsumed.toStringAsFixed(1)}g, '
        'Karb: ${carbsConsumed.toStringAsFixed(1)}g, '
        'Yağ: ${fatConsumed.toStringAsFixed(1)}g). '
        'Kalan bütçe: $remaining kcal. '
        'Tavsiyeyi bu bağlama göre kişiselleştir. Türkçe yaz.',
      ),
      DataPart('image/jpeg', imageBytes),
    ]);

    final response = await model.generateContent([prompt]);
    final text = response.text ?? '';

    // Extract JSON from response (handle markdown code blocks)
    String jsonStr = text.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.replaceAll(RegExp(r'^```\w*\n?'), '');
      jsonStr = jsonStr.replaceAll(RegExp(r'\n?```$'), '');
    }

    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return MealModel.fromJson(json);
  }
}
