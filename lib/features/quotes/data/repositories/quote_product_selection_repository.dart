import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/quote_aggregated_product.dart';
import '../../domain/models/quote_product_source.dart';

class QuoteProductSelectionRepository {
  final SupabaseClient _supabase;

  QuoteProductSelectionRepository(this._supabase);

  Future<List<QuoteAggregatedProduct>> getQuoteProductSuggestions() async {
    final response = await _supabase.rpc('get_quote_product_suggestions');
    return (response as List)
        .map((item) => QuoteAggregatedProduct.fromMap(item))
        .toList();
  }

  Future<List<QuoteProductSource>> getProductSources({
    required String name,
    required String brand,
    required String model,
    required String uom,
  }) async {
    final response = await _supabase.rpc(
      'get_product_sources',
      params: {
        'p_name': name,
        'p_brand': brand,
        'p_model': model,
        'p_uom': uom,
      },
    );
    return (response as List)
        .map((item) => QuoteProductSource.fromMap(item))
        .toList();
  }
}
