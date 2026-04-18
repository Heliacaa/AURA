import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../shared/models/chat_message_model.dart';
import '../../../shared/models/memory_model.dart';

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

  /// Build system prompt with user context, health data, and memories (RAG)
  String buildSystemPrompt({
    required String displayName,
    required int level,
    required int streak,
    required int steps,
    double sleepHours = 0,
    int waterGlasses = 0,
    int caloriesConsumed = 0,
    int calorieGoal = 2000,
    int stepGoal = 10000,
    List<MemoryModel> memories = const [],
  }) {
    final memoryContext = memories.isNotEmpty
        ? '\n\nKullanıcının daha önce paylaştığı önemli bilgiler:\n${memories.map((m) => '- [${m.category}] ${m.content}${m.relevantDate != null ? ' (Tarih: ${m.relevantDate!.toIso8601String().substring(0, 10)})' : ''}').join('\n')}'
        : '';

    return '''
Sen AURA adlı kişisel yaşam koçusun. Kullanıcının sağlık, spor, beslenme, 
sosyal enerji ve kişisel gelişim konularında rehberlik ediyorsun. 
Kullanıcının adı $displayName, seviyesi $level, serisi $streak gün.

Bugünkü veriler:
- Adım sayısı: $steps / $stepGoal
- Su: $waterGlasses bardak
- Kalori: $caloriesConsumed / $calorieGoal kcal
- Uyku: ${sleepHours > 0 ? '${sleepHours}h' : 'Kayıt yok'}
$memoryContext

Kısa, motive edici ve samimi cevaplar ver. Türkçe konuş.
Eğer kullanıcının yaklaşan etkinlikleri veya hedefleri varsa, proaktif olarak hatırlat ve tavsiyelerde bulun.
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
