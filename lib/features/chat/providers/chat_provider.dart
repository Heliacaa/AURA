import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/chat_message_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../../services/firestore_service.dart';
import '../services/gemini_service.dart';

/// Chat messages stream
final chatMessagesProvider = StreamProvider<List<ChatMessageModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();
  return FirestoreService.instance.chatMessagesStream(user.uid);
});

/// Chat loading state
final chatLoadingProvider = StateProvider<bool>((ref) => false);

/// Chat input text
final chatInputProvider = StateProvider<String>((ref) => '');

/// Send message notifier
class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ChatNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> sendMessage(String text) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (user == null || authUser == null) return;

    ref.read(chatLoadingProvider.notifier).state = true;

    try {
      // Save user message
      final userMsg = ChatMessageModel.user(text);
      await FirestoreService.instance.saveChatMessage(authUser.uid, userMsg);

      // Get recent history for context
      final history =
          await FirestoreService.instance.getRecentMessages(authUser.uid, 20);

      // Build system prompt with user context
      final log = ref.read(todayLogProvider).valueOrNull;
      final systemPrompt = GeminiService.instance.buildSystemPrompt(
        displayName: user.displayName,
        level: user.currentLevel,
        streak: user.streakDays,
        steps: log?.stepCount ?? 0,
      );

      // Call Gemini
      final response = await GeminiService.instance.sendMessage(
        userMessage: text,
        history: history,
        systemPrompt: systemPrompt,
      );

      // Save AI response
      final aiMsg = ChatMessageModel.assistant(response);
      await FirestoreService.instance.saveChatMessage(authUser.uid, aiMsg);

      // Award XP for chat interaction
      await FirestoreService.instance.updateUserXP(
        uid: authUser.uid,
        xpDelta: 10,
        statDeltas: {'intelligence': 2},
        taskDescription: '+2 Zeka (AI sohbeti)',
      );
    } finally {
      ref.read(chatLoadingProvider.notifier).state = false;
    }
  }
}

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  return ChatNotifier(ref);
});
