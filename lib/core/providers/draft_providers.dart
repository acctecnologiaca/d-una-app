import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/draft_storage_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider debe ser inicializado en main.dart y sobreescrito en ProviderScope',
  );
});

final draftStorageServiceProvider = Provider<DraftStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DraftStorageService(prefs);
});
