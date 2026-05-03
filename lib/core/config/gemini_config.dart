import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiConfig {
  GeminiConfig._();

  static const defaultTextModel = 'gemini-2.5-flash';
  static const defaultVisionModel = 'gemini-2.5-flash';

  static const _apiKeyFromDefine = String.fromEnvironment('GEMINI_API_KEY');
  static const _modelFromDefine = String.fromEnvironment('GEMINI_MODEL');
  static const _textModelFromDefine = String.fromEnvironment(
    'GEMINI_TEXT_MODEL',
  );
  static const _visionModelFromDefine = String.fromEnvironment(
    'GEMINI_VISION_MODEL',
  );

  static String get apiKey =>
      _firstNonEmpty([_apiKeyFromDefine, dotenv.env['GEMINI_API_KEY']]);

  static String get textModel => _firstNonEmpty([
    _textModelFromDefine,
    _modelFromDefine,
    dotenv.env['GEMINI_TEXT_MODEL'],
    dotenv.env['GEMINI_MODEL'],
    defaultTextModel,
  ]);

  static String get visionModel => _firstNonEmpty([
    _visionModelFromDefine,
    _modelFromDefine,
    dotenv.env['GEMINI_VISION_MODEL'],
    dotenv.env['GEMINI_MODEL'],
    defaultVisionModel,
  ]);

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }
}
