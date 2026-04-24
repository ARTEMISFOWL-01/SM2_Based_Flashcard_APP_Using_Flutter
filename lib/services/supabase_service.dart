import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/flashcard.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  String get userId => supabase.auth.currentUser!.id;

  // ─── Decks ──────────────────────────────────────────────────────────────────

  Future<void> addDeck(String title) async {
    await supabase.from('decks').insert({
      'title': title,
      'user_id': userId,
    });
  }

  Future<List<Map<String, dynamic>>> getDecks() async {
    final data = await supabase
        .from('decks')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> deleteDeck(String deckId) async {
    await supabase.from('decks').delete().eq('id', deckId);
  }

  // ─── Flashcards ─────────────────────────────────────────────────────────────

  Future<void> addFlashcard({
    required String deckId,
    required String question,
    required String answer,
    String? imageUrl,
  }) async {
    await supabase.from('flashcards').insert({
      'deck_id': deckId,
      'question': question,
      'answer': answer,
      'image_url': imageUrl,
      'user_id': userId,
      // SM-2 defaults
      'recall_probability': 0.5,
      'correct_count': 0,
      'interval': 1,
      'ease_factor': 2.5,
      'repetitions': 0,
      'next_review': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getFlashcards(String deckId) async {
    final data = await supabase
        .from('flashcards')
        .select()
        .eq('deck_id', deckId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Returns cards due for review today. If [ignoreSchedule] is true, returns all cards.
  Future<List<Map<String, dynamic>>> getStudyFlashcards(String deckId,
      {bool ignoreSchedule = false}) async {
    var query = supabase.from('flashcards').select().eq('deck_id', deckId);
    if (!ignoreSchedule) {
      query = query.lte('next_review', DateTime.now().toIso8601String());
    }
    final data = await query.order('next_review', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Update a card after SM-2 rating
  Future<void> rateCard({
    required String cardId,
    required int quality, // 0–5
    required int currentInterval,
    required double currentEF,
    required int currentRepetitions,
    required int currentCorrectCount,
  }) async {
    final result = applySM2(
      quality: quality,
      interval: currentInterval,
      easeFactor: currentEF,
      repetitions: currentRepetitions,
    );

    final newCorrectCount =
        quality >= 3 ? currentCorrectCount + 1 : currentCorrectCount;

    // Compute recall probability from new interval & EF
    final recallProb = (quality >= 3 ? 0.9 : 0.4).clamp(0.1, 0.99);

    await supabase.from('flashcards').update({
      'interval': result.interval,
      'ease_factor': result.easeFactor,
      'repetitions': result.repetitions,
      'correct_count': newCorrectCount,
      'recall_probability': recallProb,
      'next_review': result.nextReview.toIso8601String(),
    }).eq('id', cardId);
  }

  Future<void> deleteFlashcard(String cardId) async {
    await supabase.from('flashcards').delete().eq('id', cardId);
  }

  Future<List<Map<String, dynamic>>> getAllFlashcards() async {
    final data = await supabase
        .from('flashcards')
        .select('recall_probability, correct_count, interval, ease_factor, repetitions').eq('user_id', userId);
    return List<Map<String, dynamic>>.from(data);
  }

  // ─── Image Upload ────────────────────────────────────────────────────────────

  Future<String> uploadFlashcardImage(XFile file) async {
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    final bytes = await file.readAsBytes();
    await supabase.storage
        .from('flashcard-images')
        .uploadBinary(fileName, bytes);
    return supabase.storage
        .from('flashcard-images')
        .getPublicUrl(fileName);
  }
}
