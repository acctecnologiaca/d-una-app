import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/lookup_repository.dart';
import '../../data/models/service_rate_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/brand_model.dart';

final lookupRepositoryProvider = Provider<LookupRepository>((ref) {
  return LookupRepository(Supabase.instance.client);
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(lookupRepositoryProvider).getCategories();
});

final brandsProvider = FutureProvider<List<Brand>>((ref) async {
  return ref.watch(lookupRepositoryProvider).getBrands();
});

final serviceRatesProvider = FutureProvider<List<ServiceRate>>((ref) async {
  return ref.watch(lookupRepositoryProvider).getServiceRates();
});
