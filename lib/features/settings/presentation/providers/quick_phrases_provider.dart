import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/quick_phrase.dart';
import '../../data/repositories/quick_phrases_repository.dart';

final quickPhrasesRepositoryProvider = Provider<QuickPhrasesRepository>((ref) {
  return QuickPhrasesRepository(Supabase.instance.client);
});

final quickPhrasesProvider = FutureProvider<List<QuickPhrase>>((ref) async {
  return ref.watch(quickPhrasesRepositoryProvider).getQuickPhrases();
});

class QuickPhraseFilterParams {
  final QuickPhraseFieldType fieldType;
  final String? categoryId;

  const QuickPhraseFilterParams({
    required this.fieldType,
    this.categoryId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuickPhraseFilterParams &&
          runtimeType == other.runtimeType &&
          fieldType == other.fieldType &&
          categoryId == other.categoryId;

  @override
  int get hashCode => fieldType.hashCode ^ categoryId.hashCode;
}

final quickPhrasesForFieldProvider =
    Provider.family<List<String>, QuickPhraseFilterParams>((ref, params) {
      final phrasesAsync = ref.watch(quickPhrasesProvider);

      return phrasesAsync.maybeWhen(
        data: (phrases) {
          final matchingPhrases = phrases.where((p) {
            if (p.fieldType != params.fieldType) return false;
            // Include phrase if it is global (categoryId == null) OR matches the selected category
            if (p.categoryId == null) return true;
            return params.categoryId != null && p.categoryId == params.categoryId;
          }).map((p) => p.phrase).toList();

          if (matchingPhrases.isNotEmpty) {
            return matchingPhrases;
          }

          // Fallback to universal default phrases for this field type
          return kUniversalDefaultPhrases
              .where((u) => u.fieldType == params.fieldType)
              .map((u) => u.phrase)
              .toList();
        },
        orElse: () {
          // Fallback while loading or on error
          return kUniversalDefaultPhrases
              .where((u) => u.fieldType == params.fieldType)
              .map((u) => u.phrase)
              .toList();
        },
      );
    });
