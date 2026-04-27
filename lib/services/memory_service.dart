import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../shared/models/memory_model.dart';

class MemoryService {
  MemoryService._();
  static final instance = MemoryService._();

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  GenerativeModel? _model;
  GenerativeModel get model {
    _model ??= GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _apiKey);
    return _model!;
  }

  CollectionReference _memories(String uid) =>
      _db.collection('users').doc(uid).collection('memories');

  /// Extract actionable facts from a user message using Gemini
  Future<List<MemoryModel>> extractMemories(String userMessage) async {
    if (_apiKey.isEmpty) return [];

    try {
      final prompt = '''
Analyze the following user message and extract actionable facts or upcoming events.
Return a JSON array of objects with: {"content": "string", "category": "exam|health|social|work|goal", "relevantDate": "YYYY-MM-DD or null"}.
If no actionable facts found, return an empty array [].
Only return the JSON array, nothing else.

User message: "$userMessage"
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '[]';

      String jsonStr = text;
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'^```\w*\n?'), '');
        jsonStr = jsonStr.replaceAll(RegExp(r'\n?```$'), '');
      }

      final List<dynamic> jsonList = jsonDecode(jsonStr) as List<dynamic>;
      return jsonList
          .map((item) {
            try {
              // Only parse if it has valid category and content
              if (item is Map<String, dynamic> && item.containsKey('content')) {
                return MemoryModel(
                  content: item['content'] as String,
                  category: item['category'] as String? ?? 'general',
                  extractedAt: DateTime.now(),
                  relevantDate: item['relevantDate'] != null 
                      ? DateTime.tryParse(item['relevantDate'].toString()) 
                      : null,
                );
              }
            } catch (_) {}
            return null;
          })
          .whereType<MemoryModel>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save extracted memories to Firestore
  Future<void> saveMemories(String uid, List<MemoryModel> memories) async {
    final batch = _db.batch();
    for (final memory in memories) {
      batch.set(_memories(uid).doc(), memory.toFirestore());
    }
    await batch.commit();
  }

  /// Get recent memories for context enrichment
  Future<List<MemoryModel>> getRelevantMemories(String uid,
      {int limit = 10}) async {
    final snap = await _memories(uid)
        .orderBy('extractedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => MemoryModel.fromFirestore(d)).toList();
  }

  /// Extract and save memories from a user message (fire-and-forget)
  Future<void> processMessage(String uid, String userMessage) async {
    final memories = await extractMemories(userMessage);
    if (memories.isNotEmpty) {
      await saveMemories(uid, memories);
    }
  }

  /// Delete memories older than 30 days
  Future<void> cleanOldMemories(String uid) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final snap = await _memories(uid)
        .where('extractedAt', isLessThan: Timestamp.fromDate(cutoff))
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
