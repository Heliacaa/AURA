import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../shared/models/chat_message_model.dart';

class GeminiService {
  GeminiService._();
  static final instance = GeminiService._();

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  GenerativeModel? _model;

  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    return _model!;
  }

  /// Build system prompt with user context
  String buildSystemPrompt({
    required String displayName,
    required int level,
    required int streak,
    required int steps,
  }) {
    return '''
Sen AURA adlı kişisel yaşam koçusun. Kullanıcının sağlık, spor, beslenme, 
sosyal enerji ve kişisel gelişim konularında rehberlik ediyorsun. 
Kullanıcının adı $displayName, seviyesi $level, serisi $streak gün.
Bugünkü adım sayısı: $steps. Kısa, motive edici ve samimi cevaplar ver.
Türkçe konuş.
''';
  }

  /// Send a message with conversation history
  Future<String> sendMessage({
    required String userMessage,
    required List<ChatMessageModel> history,
    required String systemPrompt,
  }) async {
    if (_apiKey.isEmpty) {
      return 'API anahtarı yapılandırılmamış. Uygulamayı --dart-define=GEMINI_API_KEY=YOUR_KEY ile çalıştırın.';
    }

    final chat = model.startChat(
      history: [
        Content.text(systemPrompt),
        ...history.map((msg) {
          if (msg.isUser) {
            return Content.text(msg.content);
          } else {
            return Content.model([TextPart(msg.content)]);
          }
        }),
      ],
    );

    final response = await chat.sendMessage(Content.text(userMessage));
    return response.text ?? 'Yanıt alınamadı.';
  }
}
