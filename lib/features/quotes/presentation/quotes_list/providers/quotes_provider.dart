import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/repositories/quotes_repository.dart';
import '../../../data/repositories/supabase_quotes_repository.dart';

final quotesRepositoryProvider = Provider<QuotesRepository>((ref) {
  return SupabaseQuotesRepository(Supabase.instance.client);
});
