import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quick_phrase.dart';

class QuickPhrasesRepository {
  final SupabaseClient _client;

  QuickPhrasesRepository(this._client);

  Future<List<QuickPhrase>> getQuickPhrases() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      final response = await _client
          .from('quick_phrases')
          .select('*, categories(id, name)')
          .eq('user_id', currentUserId)
          .order('order_index', ascending: true)
          .order('created_at', ascending: true);

      final phrases = (response as List)
          .map((e) => QuickPhrase.fromJson(e))
          .toList();

      if (phrases.isEmpty) {
        // Auto-seed default universal phrases for first-time user
        await seedDefaultPhrases(currentUserId);
        final seededResponse = await _client
            .from('quick_phrases')
            .select('*, categories(id, name)')
            .eq('user_id', currentUserId)
            .order('order_index', ascending: true)
            .order('created_at', ascending: true);

        return (seededResponse as List)
            .map((e) => QuickPhrase.fromJson(e))
            .toList();
      }

      return phrases;
    } catch (e) {
      debugPrint('Error fetching quick phrases from Supabase: $e');
      rethrow;
    }
  }

  Future<QuickPhrase> addQuickPhrase({
    required QuickPhraseFieldType fieldType,
    required String phrase,
    String? categoryId,
    int orderIndex = 0,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    final data = {
      'user_id': currentUserId,
      'field_type': fieldType.dbValue,
      'category_id': categoryId,
      'phrase': phrase.trim(),
      'order_index': orderIndex,
    };

    final response = await _client
        .from('quick_phrases')
        .insert(data)
        .select('*, categories(id, name)')
        .single();

    return QuickPhrase.fromJson(response);
  }

  Future<QuickPhrase> updateQuickPhrase({
    required String id,
    required QuickPhraseFieldType fieldType,
    required String phrase,
    String? categoryId,
    int? orderIndex,
  }) async {
    final data = <String, dynamic>{
      'field_type': fieldType.dbValue,
      'category_id': categoryId,
      'phrase': phrase.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (orderIndex != null) {
      data['order_index'] = orderIndex;
    }

    final response = await _client
        .from('quick_phrases')
        .update(data)
        .eq('id', id)
        .select('*, categories(id, name)')
        .single();

    return QuickPhrase.fromJson(response);
  }

  Future<void> deleteQuickPhrase(String id) async {
    await _client.from('quick_phrases').delete().eq('id', id);
  }

  Future<void> seedDefaultPhrases(String userId) async {
    try {
      final insertData = kUniversalDefaultPhrases.asMap().entries.map((entry) {
        final index = entry.key;
        final universal = entry.value;
        return {
          'user_id': userId,
          'field_type': universal.fieldType.dbValue,
          'category_id': null,
          'phrase': universal.phrase,
          'order_index': index,
        };
      }).toList();

      await _client.from('quick_phrases').insert(insertData);
    } catch (e) {
      debugPrint('Error auto-seeding quick phrases: $e');
    }
  }
}
