import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../portfolio/data/repositories/supabase_services_repository.dart';
import '../../../../portfolio/domain/repositories/services_repository.dart';
import '../../../../portfolio/data/models/service_model.dart';

// Repository Provider
final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return SupabaseServicesRepository(Supabase.instance.client);
});

// FutureProvider for Suggestions
final quoteServiceSuggestionsProvider =
    FutureProvider.autoDispose<List<ServiceModel>>((ref) {
      final repository = ref.watch(servicesRepositoryProvider);
      return repository.getServices();
    });
